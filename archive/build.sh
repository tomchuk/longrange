#!/bin/bash
set -e

echo "Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
source "$HOME/.cargo/env"

echo "Adding wasm32-unknown-unknown target..."
rustup target add wasm32-unknown-unknown

echo "Installing wasm-bindgen-cli..."
cargo install wasm-bindgen-cli --version 0.2.105

echo "Installing wasm-opt..."
if ! command -v wasm-opt &> /dev/null; then
    curl -L https://github.com/WebAssembly/binaryen/releases/download/version_117/binaryen-version_117-x86_64-linux.tar.gz | tar xz
    export PATH="$PATH:$PWD/binaryen-version_117/bin"
fi

echo "Building WASM..."
RUSTFLAGS="-C opt-level=z" cargo build --release --target wasm32-unknown-unknown

echo "Generating JS bindings..."
wasm-bindgen target/wasm32-unknown-unknown/release/longrange.wasm \
    --out-dir dist \
    --target web \
    --no-typescript

echo "Optimizing WASM with wasm-opt..."
wasm-opt -Oz -o dist/longrange_bg.wasm.opt dist/longrange_bg.wasm
mv dist/longrange_bg.wasm.opt dist/longrange_bg.wasm

echo "Stripping debug info..."
wasm-strip dist/longrange_bg.wasm || echo "wasm-strip not available, skipping"

echo "Copying static files..."
cp index.html dist/
cp _headers dist/
[ -f wrangler.toml ] && cp wrangler.toml dist/ || echo "No wrangler.toml found"

echo "Verifying WASM module..."
wasm-validate dist/longrange_bg.wasm || echo "Warning: wasm-validate not available"

echo "Build complete! Output in dist/"
echo ""
echo "=== Build Summary ==="
echo "WASM size: $(du -h dist/longrange_bg.wasm | cut -f1)"
echo "JS size: $(du -h dist/longrange.js | cut -f1)"
echo ""
echo "=== File checksums (for debugging) ==="
echo "WASM: $(shasum -a 256 dist/longrange_bg.wasm | cut -d' ' -f1)"
echo "JS: $(shasum -a 256 dist/longrange.js | cut -d' ' -f1)"
echo ""
echo "Listing dist/ contents:"
ls -la dist/
