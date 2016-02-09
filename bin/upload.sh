#! /bin/bash

. bin/build.sh

nix-env -iA backblaze-b2
backblaze-b2 authorize_account $(cat backblaze-credentials)
result/bin/b2-nix-cache $(cat bucket-name) nix-cache-key
