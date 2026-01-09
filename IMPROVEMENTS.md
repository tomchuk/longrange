Add a Units menu to the hamburger menu. You should be able to select between metric and imperial. There should be drodowns below that to select individual units for in/cm for drop/wind, MOA/MIL for angle, temp, pressure, lbs/kg for weight, m/yd for range. Selecting metric should choose metric defaults for the dropdowns, but you should be able to individually override. The selection should apply to the TOP Gun calculator as well.

Move twist rate out of the load data into Environment & Setup.

Add a slider for drop table step size and max range

Add a slider for graph max range (min is always 0)

Make subsections for Rifle (Scope Height, zero distance), Environment (Temp, pressure, wind), Settings (graph/table settings)

The config panel should be collapsed by default on mobile

When clicking an app from the hamburger memu, the menu should be hidden after clicking.

All entered data should be persisted to localStorage on change and loaded from localStorage on app load.

Each tool should have its own URL path

Add a share link on the right side of the header which encodes the configured params for the page (TOP vs Ballistics) into a Base64-encoded URL fragment which will be loaded and populated.

X-axis graph labels and line markers should be below the graph
