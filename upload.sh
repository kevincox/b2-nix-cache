#! /bin/bash

set -e

export LC_ALL=C

bucket="$1"
key="$2"

store="$(mktemp -d)"
trap 'rm -rf "$store"' EXIT

nix-push --dest "$store" --key-file "$key" "$(nix-build)"

comm -23 --check-order \
	<(find "$store" -type f | cut -c$((${#store} + 2))- | sort) \
	<(while :; do
		r="$(backblaze-b2 list_file_names "$bucket" "$next" 1000)"
		jq -r '.files[].fileName' <<<"$r"
		
		next="$(jq -r '.nextFileName' <<<"$r")"
		[ "$(jq -r '.nextFileName | type' <<<"$r")" = 'null' ] && break
	done) | \
		parallel -j4 --halt now,fail=1 \
			backblaze-b2 upload_file "$bucket" "$store/{}" "{}"

