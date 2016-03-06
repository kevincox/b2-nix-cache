#! /bin/bash

set -e

bucket="$1"
key="$2"
shift 2

if [ -n "$*" ]; then
	paths=("$@")
else
	paths=(result*)
fi

echo "Pushing the following paths to the cache:"
for p in "${paths[@]}"; do
	echo "  $p -> $(realpath "$p")"
done

store="$(mktemp -d)"
trap 'rm -rf "$store"' EXIT

nix-push --dest "$store" --key-file "$key" "${paths[@]}"

comm -23 --check-order \
	<(find "$store" -type f | cut -c$((${#store} + 2))- | sort) \
	<(while :; do
		r="$(backblaze-b2 list_file_names "$bucket" "$next" 1000)"
		jq -r '.files[].fileName' <<<"$r"
		
		next="$(jq -r '.nextFileName' <<<"$r")"
		[ "$(jq -r '.nextFileName | type' <<<"$r")" = 'null' ] && break
	done) | \
		parallel -v -j1 --retries 3 \
			backblaze-b2 upload_file "$bucket" "$store/{}" "{}"

