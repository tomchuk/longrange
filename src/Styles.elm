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
    position: relative;
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
}

.menu-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.7);
    z-index: 99;
}

.menu {
    position: fixed;
    top: 0;
    left: 0;
    bottom: 0;
    width: 280px;
    background: #1a1a1a;
    padding: 2rem;
    border-right: 1px solid #333;
}

.menu h2 {
    margin-bottom: 1.5rem;
    color: #4a9eff;
    font-size: 1.2rem;
}

.menu-item {
    display: block;
    width: 100%;
    padding: 1rem;
    margin-bottom: 0.5rem;
    background: #252525;
    border: 1px solid #333;
    border-radius: 8px;
    color: #e0e0e0;
    font-size: 1rem;
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
    max-width: 1400px;
    margin: 0 auto;
    width: 100%;
}

.tool-container {
    display: grid;
    grid-template-columns: 350px 1fr;
    gap: 2rem;
}

.tool-container-ballistics {
    display: grid;
    grid-template-columns: 350px 1fr;
    gap: 2rem;
}

.controls {
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
}

.parameter-group {
    background: #1a1a1a;
    padding: 1.5rem;
    border-radius: 12px;
    border: 1px solid #333;
}

.parameter-group h2 {
    color: #4a9eff;
    margin-bottom: 1rem;
    font-size: 1.1rem;
}

.input-group {
    margin-bottom: 1.2rem;
}

.label-row {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 0.5rem;
}

label {
    color: #b0b0b0;
    font-size: 0.9rem;
}

.value {
    color: #4a9eff;
    font-weight: 600;
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
    width: 18px;
    height: 18px;
    background: #4a9eff;
    border-radius: 50%;
    cursor: pointer;
}

input[type="range"]::-moz-range-thumb {
    width: 18px;
    height: 18px;
    background: #4a9eff;
    border-radius: 50%;
    cursor: pointer;
    border: none;
}

select {
    width: 100%;
    padding: 0.6rem;
    background: #252525;
    border: 1px solid #333;
    border-radius: 6px;
    color: #e0e0e0;
    font-size: 0.95rem;
    cursor: pointer;
}

.results {
    background: #1a1a1a;
    padding: 1.5rem;
    border-radius: 12px;
    border: 1px solid #333;
}

.results h2 {
    color: #4a9eff;
    margin-bottom: 1rem;
    font-size: 1.1rem;
}

.result-row {
    display: flex;
    justify-content: space-between;
    padding: 0.6rem 0;
    border-bottom: 1px solid #252525;
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

.chart-container {
    background: #1a1a1a;
    padding: 2rem;
    border-radius: 12px;
    border: 1px solid #333;
}

.chart-info {
    margin-top: 1rem;
    padding: 0.8rem;
    background: #252525;
    border-radius: 8px;
    color: #b0b0b0;
    min-height: 3rem;
}

.load-selector {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
}

.load-button {
    padding: 0.8rem;
    background: #252525;
    border: 1px solid #333;
    border-radius: 6px;
    color: #e0e0e0;
    cursor: pointer;
    transition: all 0.2s;
    text-align: left;
    font-size: 0.9rem;
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
    width: 32px;
    height: 32px;
    padding: 0;
    background: #333;
    border: 1px solid #444;
    border-radius: 4px;
    color: #666;
    cursor: pointer;
    font-size: 1rem;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 0.2s;
}

.load-primary-btn:hover {
    background: #3a3a3a;
    border-color: #ffd43b;
    color: #ffd43b;
}

.load-primary-btn.active {
    background: #3a3a2a;
    border-color: #ffd43b;
    color: #ffd43b;
}

.load-edit-btn,
.load-remove-btn {
    width: 32px;
    height: 32px;
    padding: 0;
    background: #333;
    border: 1px solid #444;
    border-radius: 4px;
    color: #b0b0b0;
    cursor: pointer;
    font-size: 1rem;
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
    padding: 0.8rem;
    background: #1a3a5a;
    border: 1px solid #4a9eff;
    border-radius: 6px;
    color: #4a9eff;
    cursor: pointer;
    font-size: 0.95rem;
    font-weight: 600;
    transition: all 0.2s;
    margin-top: 0.5rem;
}

.add-load-btn:hover {
    background: #2a4a6a;
}

.load-editor {
    background: #1a1a1a;
    padding: 1.5rem;
    border-radius: 12px;
    border: 2px solid #4a9eff;
    margin-top: 1rem;
}

.load-editor h2 {
    color: #4a9eff;
    margin-bottom: 1rem;
    font-size: 1.1rem;
}

.text-input {
    width: 100%;
    padding: 0.6rem;
    background: #252525;
    border: 1px solid #333;
    border-radius: 6px;
    color: #e0e0e0;
    font-size: 0.95rem;
}

.text-input:focus {
    outline: none;
    border-color: #4a9eff;
}

.editor-buttons {
    display: flex;
    gap: 0.8rem;
    margin-top: 1rem;
}

.save-btn,
.cancel-btn {
    flex: 1;
    padding: 0.8rem;
    border-radius: 6px;
    cursor: pointer;
    font-size: 0.95rem;
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

.ballistics-chart {
    background: #1a1a1a;
    padding: 2rem;
    border-radius: 12px;
    border: 1px solid #333;
    margin-bottom: 2rem;
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

.ballistics-output {
    background: #1a1a1a;
    padding: 2rem;
    border-radius: 12px;
    border: 1px solid #333;
    overflow-x: auto;
}

.ballistics-table h2 {
    color: #4a9eff;
    margin-bottom: 0.5rem;
}

.ballistics-table p {
    color: #b0b0b0;
    margin-bottom: 1.5rem;
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

@media (max-width: 900px) {
    .tool-container,
    .tool-container-ballistics {
        grid-template-columns: 1fr;
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
}
"""
