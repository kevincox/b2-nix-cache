#! /bin/bash

. bin/.lib.sh

echo '## Building'
nix-build -j2
