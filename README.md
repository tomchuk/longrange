# Long Range Calculators

Web-based ballistics calculators built with Elm for the long-range shooting community.

## Tools

### TOP (Theory of Precision) Calculator

Predicts rifle accuracy based on projectile weight, muzzle velocity, and rifle weight using the Theory of Precision formula from Applied Ballistics.

**Formulas:**
- **Kinetic Energy (ft-lbs):** `(grain_weight × velocity²) / 450,436`
- **Theory of Precision (MOA):** `KE / 200 / rifle_weight`

**Confidence bounds:** 1σ (±15%, ~68% confidence)

### Ballistics Solver

Calculates bullet trajectory including drop, wind drift, spin drift, velocity, and time of flight across multiple ranges. Features include:
- **Primary load selection** - Designate a primary load with a star (⭐) indicator for zero reference
- **Equivalent zero calculation** - Automatically calculates equivalent zero distance for secondary loads
- **Multi-load comparison** - Add, edit, and remove custom loads with full ballistic parameters
- **Trajectory chart** - Visual comparison of all loads on a single graph with color-coded lines
- **Spin drift calculation** - Accounts for gyroscopic drift based on twist rate (right-hand twist)
- **Detailed ballistics table** - Range, drop (in/MOA), wind drift, spin drift, velocity, and time of flight
- **Environment settings** - Scope height, zero distance, temperature, pressure, wind speed, and wind direction (0-360°)

## Development

### Prerequisites

- [Elm](https://guide.elm-lang.org/install/elm.html) 0.19.1

### Running Locally

1. Clone the repository
2. Install dependencies: `elm make src/Main.elm`
3. Compile the app: `elm make src/Main.elm --output=main.js`
4. Open `index.html` in your browser

Alternatively, use `elm reactor` for live development:
```bash
elm reactor
```

Then navigate to `http://localhost:8000/src/Main.elm`

### Features Overview

**TOP Gun Calculator:**
- Interactive sliders for all parameters
- Real-time accuracy calculations with confidence intervals
- Dynamic charts comparing MOA vs rifle weight/velocity/projectile weight
- Mobile-responsive design

**Ballistics Solver:**
- Set primary load and view equivalent zeros for secondary loads
- Manage multiple ammunition loads (add/edit/remove with name, weight, BC, BC model, MV, twist rate)
- Side-by-side trajectory comparison chart with legend
- Color-coded load visualization (7-color palette)
- Spin drift calculation using Litz formula approximation
- Wind direction control (0-360° with compass labels)
- Comprehensive ballistics data table with MOA conversions
- Environmental condition controls (scope height, zero distance, temperature, pressure)

## Building for Production

Compile the Elm app with optimizations:

```bash
elm make src/Main.elm --output=main.js --optimize
```

For deployment, the build output includes:
- `index.html` - Main HTML file
- `main.js` - Compiled Elm application

## Deployment to Cloudflare Pages

### Option 1: Via GitHub (Recommended)

1. Push your repository to GitHub
2. Log in to [Cloudflare Pages](https://pages.cloudflare.com/)
3. Create a new project and connect your GitHub repository
4. Configure build settings:
   - **Build command:** `elm make src/Main.elm --output=main.js --optimize`
   - **Build output directory:** `/`
   - **Root directory:** (leave empty)
5. Deploy

Cloudflare will automatically rebuild and redeploy on every push to your repository.

### Option 2: Direct Upload

1. Build the project locally (see above)
2. Create a directory with `index.html` and `main.js`
3. Use Wrangler CLI to deploy:

```bash
npx wrangler pages deploy . --project-name=longrange
```

## Project Structure

```
longrange/
├── src/
│   └── Main.elm          # Main Elm application
├── archive/              # Original Rust/Python implementations
├── elm.json              # Elm dependencies
├── index.html            # HTML wrapper
└── README.md
```

## References

- **Original TOP Gun Calculator:** [Google Sheets](https://docs.google.com/spreadsheets/d/1S0DMLcmj-Jvag5NwKrVAQUR2eOwpWTozy28jTVe998g/)
- **Theory Source:** Applied Ballistics - Modern Advancements in Long Range Shooting, Vol 3
- **Elm Charts:** [terezka/elm-charts](https://package.elm-lang.org/packages/terezka/elm-charts/latest/)

## License

See LICENSE file for details.