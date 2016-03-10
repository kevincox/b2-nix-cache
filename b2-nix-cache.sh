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

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
store="$tmp/store"

nix-push --dest "$store" --key-file "$key" "${paths[@]}"

# Get a list of local files.
find "$store" -type f | cut -c$((${#store} + 2))- | sort >"$tmp/local"

# Get a list of remote files.
while :; do
	r="$(backblaze-b2 list_file_names "$bucket" "$next" 1000)" || bbe=$?
	if [[ $bbe ]]; then
		echo "$r"
		exit $bbe
	fi
	jq -r '.files[].fileName' <<<"$r" >>"$tmp/remote"
	
	next="$(jq -r '.nextFileName' <<<"$r")"
	[ "$(jq -r '.nextFileName | type' <<<"$r")" = 'null' ] && break
done

# Upload missing files.
comm -23 --check-order "$tmp/local" "$tmp/remote" | \
	parallel -v -j1 --retries 3 \
		backblaze-b2 upload_file "$bucket" "$store/{}" "{}"

