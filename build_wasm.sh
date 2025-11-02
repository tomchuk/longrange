#!/bin/bash
set -e

echo "Building WASM target..."

# Install wasm-bindgen-cli if not present
if ! command -v wasm-bindgen &> /dev/null; then
    echo "Installing wasm-bindgen-cli..."
    cargo install wasm-bindgen-cli
fi

# Build the WASM binary
echo "Compiling to WASM..."
cargo build --release --target wasm32-unknown-unknown

# Generate JS bindings
echo "Generating JS bindings..."
wasm-bindgen target/wasm32-unknown-unknown/release/longrange.wasm \
    --out-dir dist \
    --target web \
    --no-typescript

# Copy HTML file
echo "Copying static files..."
cp index.html dist/

# Optimize WASM (optional, requires wasm-opt from binaryen)
if command -v wasm-opt &> /dev/null; then
    echo "Optimizing WASM..."
    wasm-opt -Oz -o dist/longrange_bg.wasm.opt dist/longrange_bg.wasm
    mv dist/longrange_bg.wasm.opt dist/longrange_bg.wasm
else
    echo "wasm-opt not found, skipping optimization (install binaryen for smaller binaries)"
fi

echo "Build complete! Output in dist/"
echo "To test locally, run: python3 -m http.server --directory dist 8080"
echo "Then open http://localhost:8080"
