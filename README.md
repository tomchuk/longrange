# r/longrange Calculators

Web-based ballistics calculators for the r/longrange community.

## TOP (Theory of Precision) Calculator

Predicts rifle accuracy based on projectile weight, muzzle velocity, and rifle weight using the Theory of Precision formula from Applied Ballistics.

### Formulas

- **Kinetic Energy (ft-lbs):** `(grain_weight × velocity²) / 450,436`
- **Theory of Precision (MOA):** `KE / 200 / rifle_weight`

**Note:** Confidence bounds are displayed as 1σ (±15%, ~68% confidence) and 2σ (±30%, ~95% confidence), adjusted from the original spreadsheet's values to align with standard statistical conventions.

### Building

**Native (for testing):**
```bash
cargo run --release
```

**WASM (for deployment):**
```bash
rustup target add wasm32-unknown-unknown
cargo install wasm-bindgen-cli
cargo build --release --target wasm32-unknown-unknown
wasm-bindgen target/wasm32-unknown-unknown/release/longrange.wasm --out-dir dist --target web --no-typescript
cp index.html dist/
```

Output will be in `dist/` directory.

### Deployment

Push to GitHub and connect repository to Cloudflare Pages. The `wrangler.toml` configuration will handle the build automatically.

## References

- **Original TOP Gun Calculator:** [Google Sheets](https://docs.google.com/spreadsheets/d/1S0DMLcmj-Jvag5NwKrVAQUR2eOwpWTozy28jTVe998g/)
- **Theory Source:** Applied Ballistics - Modern Advancements in Long Range Shooting, Vol 3
