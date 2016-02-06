#! /bin/bash

set -e

bin/build.sh

bash authenticate.sh
result/bin/backblaze-b2 $(cat bucket-name) nix-cache-key
