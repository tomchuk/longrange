module Styles exposing (viewStyles)

import Html exposing (Html, node, text)


viewStyles : Html msg
viewStyles =
    node "style"
        []
        [ text css ]


css : String
css =
    """
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
    background: #0f0f0f;
    color: #e0e0e0;
    line-height: 1.6;
}

.app {
    min-height: 100vh;
    display: flex;
    flex-direction: column;
}

.header {
    background: #1a1a1a;
    padding: 1rem 2rem;
    border-bottom: 1px solid #333;
    display: flex;
    align-items: center;
    gap: 1rem;
    position: sticky;
    top: 0;
    z-index: 100;
}

.menu-button {
    background: none;
    border: none;
    cursor: pointer;
    padding: 0.5rem;
}

.hamburger {
    display: flex;
    flex-direction: column;
    gap: 4px;
}

.hamburger span {
    display: block;
    width: 24px;
    height: 3px;
    background: #e0e0e0;
    border-radius: 2px;
    transition: all 0.3s;
}

.title {
    font-size: 1.5rem;
    font-weight: 600;
    color: #4a9eff;
    flex: 1;
}

.share-container {
    position: relative;
}

.share-button {
    padding: 0.5rem 1rem;
    background: #252525;
    border: 1px solid #333;
    border-radius: 6px;
    color: #e0e0e0;
    font-size: 0.85rem;
    cursor: pointer;
    transition: all 0.2s;
}

.share-button:hover {
    background: #2a2a2a;
    border-color: #4a9eff;
    color: #4a9eff;
}

.share-button:active {
    background: #1a3a5a;
}

.share-popup {
    position: absolute;
    top: 100%;
    right: 0;
    margin-top: 0.5rem;
    background: #1a1a1a;
    border: 1px solid #4a9eff;
    border-radius: 8px;
    padding: 0.75rem;
    min-width: 300px;
    z-index: 1000;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.5);
}

.share-popup-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 0.5rem;
    color: #4a9eff;
    font-size: 0.85rem;
}

.share-popup-close {
    background: none;
    border: none;
    color: #b0b0b0;
    font-size: 1.2rem;
    cursor: pointer;
    padding: 0;
    line-height: 1;
}

.share-popup-close:hover {
    color: #ff6b6b;
}

.share-url-input {
    width: 100%;
    padding: 0.5rem;
    background: #252525;
    border: 1px solid #333;
    border-radius: 4px;
    color: #e0e0e0;
    font-size: 0.75rem;
    font-family: monospace;
}

.share-url-input:focus {
    outline: none;
    border-color: #4a9eff;
}

.app-body {
    display: flex;
    flex: 1;
}

.sidebar {
    width: 480px;
    min-width: 480px;
    background: #1a1a1a;
    border-right: 1px solid #333;
    padding: 1.5rem;
    overflow-y: auto;
    max-height: calc(100vh - 60px);
    position: sticky;
    top: 60px;
}

.sidebar-section {
    margin-bottom: 1.5rem;
    padding-bottom: 1.5rem;
    border-bottom: 1px solid #333;
}

.sidebar-section:last-child {
    border-bottom: none;
    margin-bottom: 0;
    padding-bottom: 0;
}

.sidebar h2 {
    margin-bottom: 1rem;
    color: #4a9eff;
    font-size: 1.1rem;
}

.menu-item {
    display: block;
    width: 100%;
    padding: 0.8rem 1rem;
    margin-bottom: 0.5rem;
    background: #252525;
    border: 1px solid #333;
    border-radius: 8px;
    color: #e0e0e0;
    font-size: 0.95rem;
    cursor: pointer;
    transition: all 0.2s;
    text-align: left;
}

.menu-item:hover {
    background: #2a2a2a;
    border-color: #4a9eff;
}

.menu-item.active {
    background: #1a3a5a;
    border-color: #4a9eff;
    color: #4a9eff;
}

.content {
    flex: 1;
    padding: 2rem;
    overflow-y: auto;
}

.tool-output {
    width: 100%;
}

.config-section {
    margin-bottom: 1rem;
}

.config-section h3 {
    color: #4a9eff;
    margin-bottom: 0.8rem;
    margin-top: 1rem;
    font-size: 1rem;
}

.config-section h3:first-child {
    margin-top: 0;
}

.column-toggles {
    display: flex;
    flex-direction: column;
    gap: 0.4rem;
    margin-top: 0.8rem;
    padding: 0.8rem;
    background: #252525;
    border-radius: 6px;
}

.column-toggles > label:first-child {
    color: #b0b0b0;
    font-size: 0.8rem;
    margin-bottom: 0.3rem;
}

.toggle-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 0.4rem 1rem;
}

.toggle-label {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    color: #e0e0e0;
    font-size: 0.85rem;
    cursor: pointer;
}

.toggle-label input[type="checkbox"] {
    width: 16px;
    height: 16px;
    accent-color: #4a9eff;
    cursor: pointer;
}

.input-group {
    margin-bottom: 1rem;
}

.label-row {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 0.4rem;
}

label {
    color: #b0b0b0;
    font-size: 0.85rem;
}

.value {
    color: #4a9eff;
    font-weight: 600;
    font-size: 0.85rem;
}

input[type="range"] {
    width: 100%;
    height: 6px;
    background: #333;
    border-radius: 3px;
    outline: none;
}

input[type="range"]::-webkit-slider-thumb {
    -webkit-appearance: none;
    appearance: none;
    width: 16px;
    height: 16px;
    background: #4a9eff;
    border-radius: 50%;
    cursor: pointer;
}

input[type="range"]::-moz-range-thumb {
    width: 16px;
    height: 16px;
    background: #4a9eff;
    border-radius: 50%;
    cursor: pointer;
    border: none;
}

select {
    width: 100%;
    padding: 0.5rem;
    background: #252525;
    border: 1px solid #333;
    border-radius: 6px;
    color: #e0e0e0;
    font-size: 0.9rem;
    cursor: pointer;
}

select:hover {
    border-color: #4a9eff;
}

/* Units Section */
.units-section {
    margin-bottom: 1.5rem;
    padding-bottom: 1.5rem;
    border-bottom: 1px solid #333;
}

.units-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    width: 100%;
    padding: 0;
    background: none;
    border: none;
    color: #4a9eff;
    font-size: 1.1rem;
    font-weight: 600;
    cursor: pointer;
    margin-bottom: 0.8rem;
}

.units-header:hover .units-expand-icon {
    color: #4a9eff;
}

.units-expand-icon {
    font-size: 0.8rem;
    color: #b0b0b0;
    transition: color 0.2s;
}

.unit-system-selector {
    display: flex;
    gap: 0.5rem;
    margin-bottom: 0.8rem;
}

.unit-system-btn {
    flex: 1;
    padding: 0.5rem;
    background: #252525;
    border: 1px solid #333;
    border-radius: 6px;
    color: #e0e0e0;
    font-size: 0.85rem;
    cursor: pointer;
    transition: all 0.2s;
}

.unit-system-btn:hover {
    background: #2a2a2a;
    border-color: #4a9eff;
}

.unit-system-btn.active {
    background: #1a3a5a;
    border-color: #4a9eff;
    color: #4a9eff;
}

.unit-dropdowns {
    display: flex;
    flex-direction: column;
    gap: 0.6rem;
}

.unit-dropdown {
    display: flex;
    flex-direction: column;
    gap: 0.2rem;
}

.unit-dropdown label {
    color: #b0b0b0;
    font-size: 0.75rem;
}

.unit-dropdown select {
    padding: 0.4rem;
    font-size: 0.8rem;
}

/* Results Section */
.results {
    background: #1a1a1a;
    padding: 1.5rem;
    border-radius: 12px;
    border: 1px solid #333;
    margin-top: 1.5rem;
}

.results h2 {
    color: #4a9eff;
    margin-bottom: 1rem;
    font-size: 1.2rem;
}

.results-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 1rem;
}

.result-row {
    display: flex;
    justify-content: space-between;
    padding: 0.6rem;
    background: #252525;
    border-radius: 6px;
}

.result-label {
    color: #b0b0b0;
}

.result-value {
    color: #e0e0e0;
    font-weight: 600;
}

.result-confidence .result-value {
    color: #4a9eff;
}

/* Chart Container */
.chart-container {
    background: #1a1a1a;
    padding: 1.5rem;
    border-radius: 12px;
    border: 1px solid #333;
    overflow: hidden;
}

.chart-container svg {
    max-width: 100%;
    height: auto;
}

.chart-container svg path.elm-charts__line,
.ballistics-chart svg path.elm-charts__line {
    stroke-width: 0.3 !important;
    stroke: #333 !important;
}

.chart-container svg .elm-charts__x-axis path.elm-charts__line,
.chart-container svg .elm-charts__y-axis path.elm-charts__line,
.ballistics-chart svg .elm-charts__x-axis path.elm-charts__line,
.ballistics-chart svg .elm-charts__y-axis path.elm-charts__line {
    stroke-width: 0.5 !important;
    stroke: #555 !important;
}

.chart-container svg .elm-charts__x-ticks line.elm-charts__tick,
.chart-container svg .elm-charts__y-ticks line.elm-charts__tick,
.ballistics-chart svg .elm-charts__x-ticks line.elm-charts__tick,
.ballistics-chart svg .elm-charts__y-ticks line.elm-charts__tick {
    stroke-width: 0.5 !important;
    stroke: #555 !important;
}

.chart-container svg .elm-charts__arrow polygon,
.ballistics-chart svg .elm-charts__arrow polygon {
    fill: #555 !important;
}

/* Load Selector */
.load-selector {
    display: flex;
    flex-direction: column;
    gap: 0.4rem;
}

.load-button {
    padding: 0.6rem;
    background: #252525;
    border: 1px solid #333;
    border-radius: 6px;
    color: #e0e0e0;
    cursor: pointer;
    transition: all 0.2s;
    text-align: left;
    font-size: 0.85rem;
}

.load-button:hover {
    background: #2a2a2a;
    border-color: #4a9eff;
}

.load-button.active {
    background: #1a3a5a;
    border-color: #4a9eff;
    color: #4a9eff;
}

.load-item {
    display: flex;
    gap: 0.3rem;
    align-items: center;
}

.load-item .load-button {
    flex: 1;
    margin-bottom: 0;
}

.load-primary-btn {
    width: 28px;
    height: 28px;
    padding: 0;
    background: #333;
    border: 1px solid #444;
    border-radius: 4px;
    color: #666;
    cursor: pointer;
    font-size: 0.9rem;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 0.2s;
}

.load-primary-btn:hover {
    background: #3a3a3a;
    border-color: #ff6b6b;
    color: #ff6b6b;
}

.load-primary-btn.active {
    background: #3a2a2a;
    border-color: #ff6b6b;
    color: #ff6b6b;
}

.load-edit-btn,
.load-remove-btn {
    width: 28px;
    height: 28px;
    padding: 0;
    background: #333;
    border: 1px solid #444;
    border-radius: 4px;
    color: #b0b0b0;
    cursor: pointer;
    font-size: 0.9rem;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 0.2s;
}

.load-edit-btn:hover {
    background: #3a3a3a;
    border-color: #4a9eff;
    color: #4a9eff;
}

.load-remove-btn:hover {
    background: #3a3a3a;
    border-color: #ff6b6b;
    color: #ff6b6b;
}

.add-load-btn {
    width: 100%;
    padding: 0.6rem;
    background: #1a3a5a;
    border: 1px solid #4a9eff;
    border-radius: 6px;
    color: #4a9eff;
    cursor: pointer;
    font-size: 0.85rem;
    font-weight: 600;
    transition: all 0.2s;
    margin-top: 0.5rem;
}

.add-load-btn:hover {
    background: #2a4a6a;
}

/* Load Editor */
.load-editor {
    background: #252525;
    padding: 1rem;
    border-radius: 8px;
    border: 1px solid #4a9eff;
    margin-top: 1rem;
}

.load-editor h2 {
    color: #4a9eff;
    margin-bottom: 0.8rem;
    font-size: 1rem;
}

.text-input {
    width: 100%;
    padding: 0.5rem;
    background: #1a1a1a;
    border: 1px solid #333;
    border-radius: 6px;
    color: #e0e0e0;
    font-size: 0.9rem;
}

.text-input:focus {
    outline: none;
    border-color: #4a9eff;
}

.editor-buttons {
    display: flex;
    gap: 0.6rem;
    margin-top: 0.8rem;
}

.save-btn,
.cancel-btn {
    flex: 1;
    padding: 0.6rem;
    border-radius: 6px;
    cursor: pointer;
    font-size: 0.85rem;
    font-weight: 600;
    transition: all 0.2s;
}

.save-btn {
    background: #1a3a5a;
    border: 1px solid #4a9eff;
    color: #4a9eff;
}

.save-btn:hover {
    background: #2a4a6a;
}

.cancel-btn {
    background: #333;
    border: 1px solid #444;
    color: #b0b0b0;
}

.cancel-btn:hover {
    background: #3a3a3a;
    border-color: #666;
}

/* Ballistics Chart */
.ballistics-chart {
    background: #1a1a1a;
    padding: 1.5rem;
    border-radius: 12px;
    border: 1px solid #333;
    margin-bottom: 2rem;
    overflow: hidden;
}

.ballistics-chart svg {
    max-width: 100%;
    height: auto;
}

.ballistics-chart h2 {
    color: #4a9eff;
    margin-bottom: 1rem;
}

.equivalent-zeros {
    display: flex;
    flex-wrap: wrap;
    gap: 1rem;
    margin-bottom: 1.5rem;
    padding: 1rem;
    background: #252525;
    border-radius: 8px;
}

.zero-info {
    display: flex;
    gap: 0.3rem;
    font-size: 0.9rem;
}

.zero-load {
    color: #b0b0b0;
}

.zero-value {
    color: #4a9eff;
    font-weight: 600;
}

.zero-value.warning {
    color: #ff6b6b;
}

.equivalent-zero-text {
    color: #4a9eff;
    font-weight: 600;
    margin-top: 0.5rem;
}

.equivalent-zero-text.warning {
    color: #ff6b6b;
}

.chart-legend {
    display: flex;
    flex-wrap: wrap;
    gap: 1rem;
    margin-top: 1rem;
    padding: 1rem;
    background: #252525;
    border-radius: 8px;
}

.legend-item {
    display: flex;
    align-items: center;
    gap: 0.5rem;
}

.legend-color {
    width: 20px;
    height: 3px;
    border-radius: 2px;
}

/* Ballistics Table */
.ballistics-table {
    background: #1a1a1a;
    padding: 2rem;
    border-radius: 12px;
    border: 1px solid #333;
}

.ballistics-table h2 {
    color: #4a9eff;
    margin-bottom: 0.5rem;
}

.ballistics-table p {
    color: #b0b0b0;
    margin-bottom: 1rem;
    font-size: 0.9rem;
}

table {
    width: 100%;
    border-collapse: collapse;
    margin-top: 1rem;
}

thead {
    background: #252525;
}

th {
    padding: 0.8rem;
    text-align: left;
    color: #4a9eff;
    font-weight: 600;
    border-bottom: 2px solid #333;
}

td {
    padding: 0.8rem;
    border-bottom: 1px solid #252525;
}

tbody tr:hover {
    background: #252525;
}

/* Mobile Responsive */
@media (max-width: 900px) {
    .app-body {
        flex-direction: column;
    }

    .sidebar {
        width: 100%;
        min-width: 100%;
        max-height: none;
        position: static;
        border-right: none;
        border-bottom: 1px solid #333;
    }

    .header {
        padding: 1rem;
    }

    .title {
        font-size: 1.2rem;
    }

    .content {
        padding: 1rem;
    }

    .results-grid {
        grid-template-columns: 1fr;
    }
}
"""
