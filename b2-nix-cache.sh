#! /bin/bash

set -e

bucket="$1"
key="$2"
derivation="${3:-./result}"

cache=~/.cache/b2-nix-cache/exists-cache
mkdir -p "$cache"

store="$(mktemp -d)"
# trap 'rm -rf "$store"' EXIT

nix-push --dest "$store" --key-file "$key" "$derivation"

comm -23 --check-order \
	<(find "$store" -type f | cut -c$((${#store} + 2))- | sort) \
	<(while :; do
		r="$(backblaze-b2 list_file_names "$bucket" "$next" 1000)"
		jq -r '.files[].fileName' <<<"$r"
		
		next="$(jq -r '.nextFileName' <<<"$r")"
		[ "$(jq -r '.nextFileName | type' <<<"$r")" = 'null' ] && break
	done) | \
		parallel -v -j4 --halt now,fail=1 \
			backblaze-b2 upload_file "$bucket" "$store/{}" "{}"

