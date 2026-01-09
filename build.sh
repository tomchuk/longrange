#!/usr/bin/env bash

set -e

echo "Building Elm application for production..."

# Clean previous build
rm -f main.js

# Compile Elm with optimizations
echo "Compiling Elm..."
elm make src/Main.elm --output=main.js --optimize

echo "Build complete!"
echo "Files ready for deployment:"
echo "  - index.html"
echo "  - main.js ($(du -h main.js | cut -f1))"
echo ""
echo "To deploy to Cloudflare Pages:"
echo "  npx wrangler pages deploy . --project-name=longrange"
