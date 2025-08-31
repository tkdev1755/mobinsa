#!/bin/bash
set -e

# Chemins
LIB_DIR="$PWD/../lib/KeychainAPI/macos/"
OUTPUT_DIR="$PWD/libs/"

# Crée le dossier libs s'il n'existe pas
mkdir -p "$OUTPUT_DIR"

# Compile la librairie
cd "$LIB_DIR"
make clean
make

# Copie la .dylib dans macos/libs
cp libkeychain.dylib "$OUTPUT_DIR/"

echo "✅ Librairie native compilée et copiée dans $OUTPUT_DIR"