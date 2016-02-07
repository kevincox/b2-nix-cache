#! /bin/bash

set -e

. bin/.lib.sh

nix-build -j2
