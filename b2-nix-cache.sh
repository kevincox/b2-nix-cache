#! /bin/bash

set -eu

if [[ $# < 2 ]]; then
	echo 'Usage: b2-nix-cache <bucket> <key path> [<store path>...]'
	exit 64
fi

bucket="$1"
key="$2"

if [[ $# > 2 ]]; then
	paths=${@:3}
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

backblaze-b2 sync --compareVersions none "$store" "b2://$bucket"
