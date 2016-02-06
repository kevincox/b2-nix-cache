#! /bin/bash

set -e

bash <(curl -sS https://nixos.org/nix/install)
source $HOME/.nix-profile/etc/profile.d/nix.sh
nix-build -j2
