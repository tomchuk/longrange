#!/usr/bin/env bash

set -e

echo "Building Elm application for production..."

# Clean and create dist directory
rm -rf dist
mkdir -p dist

# Compile Elm with optimizations
echo "Compiling Elm..."
npx elm make src/Main.elm --output=dist/main.js --optimize

# Copy static files
cp index.html dist/
cp _redirects dist/

echo "Build complete!"
echo "Files ready for deployment in dist/:"
echo "  - index.html"
echo "  - main.js ($(du -h dist/main.js | cut -f1))"
echo "  - _redirects"
