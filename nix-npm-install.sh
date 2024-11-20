#!/usr/bin/env bash
tempdir="/tmp/nix-npm-install/$1"
mkdir -p $tempdir
pushd $tempdir
node2nix -18 --input <( echo "[\"$1\"]")
#nix-env --install --file .
popd

