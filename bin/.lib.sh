set -ex

[ '!' -d /nix ] && bash <(curl -sS https://nixos.org/nix/install)
. ~/.nix-profile/etc/profile.d/nix.sh

cache="${SEMAPHORE_CACHE_DIR:-/tmp/b2-nix-cache-build-cache}"

nixpkgs="$cache/nixpkgs"
pkgsref="$(cat nixpkgs)"
if [ -d "$nixpkgs" ]; then
	(cd "$nixpkgs" && git fetch origin)
else
	git clone 'https://github.com/NixOS/nixpkgs.git' $nixpkgs
fi
(cd "$nixpkgs" && git reset --hard "$pkgsref")
rm -rf ~/.nix-defexpr
ln -s "$nixpkgs" ~/.nix-defexpr
export "NIX_PATH=nixpkgs=$nixpkgs"
