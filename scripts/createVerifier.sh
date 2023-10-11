#!/bin/bash

# Stop execution if any step returns non-zero (non success) status
set -e

if [ -z "$1" ]; then
    echo "No zkey file name provided."
    exit 1
fi

mkdir -p src
snarkjs zkey export solidityverifier ./build/$1 src/Verifier.sol