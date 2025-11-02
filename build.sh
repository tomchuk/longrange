#!/bin/bash
set -e

echo "Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
source "$HOME/.cargo/env"

echo "Adding wasm32-unknown-unknown target..."
rustup target add wasm32-unknown-unknown

echo "Installing wasm-bindgen-cli..."
cargo install wasm-bindgen-cli --version 0.2.92

echo "Building WASM..."
cargo build --release --target wasm32-unknown-unknown

echo "Generating JS bindings..."
wasm-bindgen target/wasm32-unknown-unknown/release/longrange.wasm \
    --out-dir dist \
    --target web \
    --no-typescript

echo "Copying static files..."
cp index.html dist/

echo "Build complete! Output in dist/"
