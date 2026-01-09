#!/usr/bin/env python3
"""
Simple ballistics solver with equivalent zero calculation.
"""
import math

# =============================================================================
# CONFIGURATION
# =============================================================================

# Environment
TEMP_F = 60.0           # Temperature in Fahrenheit
PRESSURE_INHG = 29.92   # Pressure in inches of mercury
WIND_MPH = 10.0         # Full-value (90°) wind speed in mph

# Rifle setup
SCOPE_HEIGHT_IN = 1.9   # Scope height over bore in inches
ZERO_DISTANCE_YD = 100  # Zero distance in yards

# Primary load (scope is zeroed for this)
PRIMARY = {
    "name": "NAS3 175Gr LRX",
    "weight_gr": 175,
    "bc": 0.254,
    "model": "G7",      # "G1" or "G7"
    "mv_fps": 2725,
}

# Secondary loads (find equivalent zero for these)
SECONDARY = [
    {
        "name": "NAS3 150 TTSX",
        "weight_gr": 150,
        "bc": 0.440,
        "model": "G1",
        "mv_fps": 2950,
    },
    {
        "name": "Barnes 130Gr TTSX",
        "weight_gr": 130,
        "bc": 0.350,
        "model": "G1",
        "mv_fps": 3125,
    },
    {
        "name": "Barnes 150Gr TTSX",
        "weight_gr": 150,
        "bc": 0.440,
        "model": "G1",
        "mv_fps": 2900,
    },
    {
        "name": "Barnes 168Gr TTSX",
        "weight_gr": 168,
        "bc": 0.470,
        "model": "G1",
        "mv_fps": 2700,
    },
    # Add more loads here as needed
]

# =============================================================================
# CONSTANTS
# =============================================================================

GRAVITY = 32.174        # ft/s²
STD_TEMP_F = 59.0       # Standard atmosphere reference
STD_PRESSURE_INHG = 29.92

# G1 drag table: (Mach, Cd)
G1_TABLE = [
    (0.00, 0.2629), (0.50, 0.2558), (0.60, 0.2487), (0.70, 0.2413),
    (0.80, 0.2344), (0.85, 0.2349), (0.875, 0.2402), (0.90, 0.2512),
    (0.925, 0.2788), (0.95, 0.3142), (0.975, 0.3462), (1.00, 0.3734),
    (1.025, 0.3949), (1.05, 0.4084), (1.075, 0.4154), (1.10, 0.4177),
    (1.125, 0.4166), (1.15, 0.4133), (1.20, 0.4023), (1.25, 0.3887),
    (1.30, 0.3741), (1.35, 0.3594), (1.40, 0.3451), (1.45, 0.3314),
    (1.50, 0.3186), (1.55, 0.3068), (1.60, 0.2960), (1.65, 0.2862),
    (1.70, 0.2774), (1.75, 0.2694), (1.80, 0.2621), (1.85, 0.2555),
    (1.90, 0.2495), (1.95, 0.2440), (2.00, 0.2388), (2.05, 0.2340),
    (2.10, 0.2296), (2.15, 0.2254), (2.20, 0.2215), (2.25, 0.2179),
    (2.30, 0.2144), (2.35, 0.2111), (2.40, 0.2080), (2.45, 0.2051),
    (2.50, 0.2023), (2.60, 0.1972), (2.70, 0.1926), (2.80, 0.1884),
    (2.90, 0.1846), (3.00, 0.1812),
]

# G7 drag table: (Mach, Cd)
G7_TABLE = [
    (0.00, 0.1198), (0.50, 0.1197), (0.60, 0.1196), (0.70, 0.1194),
    (0.80, 0.1193), (0.85, 0.1194), (0.875, 0.1210), (0.90, 0.1256),
    (0.925, 0.1382), (0.95, 0.1618), (0.975, 0.1903), (1.00, 0.2124),
    (1.025, 0.2278), (1.05, 0.2378), (1.075, 0.2436), (1.10, 0.2464),
    (1.125, 0.2470), (1.15, 0.2460), (1.20, 0.2405), (1.25, 0.2318),
    (1.30, 0.2218), (1.35, 0.2115), (1.40, 0.2015), (1.45, 0.1920),
    (1.50, 0.1832), (1.55, 0.1750), (1.60, 0.1676), (1.65, 0.1608),
    (1.70, 0.1547), (1.75, 0.1491), (1.80, 0.1440), (1.85, 0.1393),
    (1.90, 0.1350), (1.95, 0.1310), (2.00, 0.1273), (2.05, 0.1239),
    (2.10, 0.1207), (2.15, 0.1178), (2.20, 0.1150), (2.25, 0.1125),
    (2.30, 0.1101), (2.35, 0.1078), (2.40, 0.1058), (2.45, 0.1038),
    (2.50, 0.1020), (2.60, 0.0987), (2.70, 0.0957), (2.80, 0.0929),
    (2.90, 0.0904), (3.00, 0.0880),
]


def interpolate_cd(mach: float, table: list) -> float:
    """Linearly interpolate drag coefficient from table."""
    if mach <= table[0][0]:
        return table[0][1]
    if mach >= table[-1][0]:
        return table[-1][1]
    for i in range(len(table) - 1):
        if table[i][0] <= mach <= table[i + 1][0]:
            t = (mach - table[i][0]) / (table[i + 1][0] - table[i][0])
            return table[i][1] + t * (table[i + 1][1] - table[i][1])
    return table[-1][1]


def get_cd(mach: float, model: str) -> float:
    """Get drag coefficient for given Mach and drag model."""
    table = G7_TABLE if model.upper() == "G7" else G1_TABLE
    return interpolate_cd(mach, table)


def speed_of_sound(temp_f: float) -> float:
    """Speed of sound in ft/s given temperature in Fahrenheit."""
    temp_r = temp_f + 459.67
    return 49.0223 * math.sqrt(temp_r)


def air_density_ratio(temp_f: float, pressure_inhg: float) -> float:
    """Air density relative to standard atmosphere."""
    std_temp_r = STD_TEMP_F + 459.67
    temp_r = temp_f + 459.67
    return (pressure_inhg / STD_PRESSURE_INHG) * (std_temp_r / temp_r)


def simulate_trajectory(
    bc: float,
    model: str,
    mv_fps: float,
    launch_angle_rad: float,
    scope_height_ft: float,
    zero_range_ft: float,
    temp_f: float,
    pressure_inhg: float,
    wind_fps: float,
    max_range_ft: float,
    dt: float = 0.0001,
    record_interval_ft: float = 300.0,  # Default: every 100 yards
) -> list:
    """
    Simulate bullet trajectory.
    Returns list of (range_ft, drop_ft, wind_drift_ft, velocity_fps, tof_s).
    Drop is relative to line of sight (scope axis).
    """
    sos = speed_of_sound(temp_f)
    rho_ratio = air_density_ratio(temp_f, pressure_inhg)

    # Initial conditions (bore is at origin, pointed at launch_angle)
    x, y = 0.0, 0.0  # Position relative to bore
    vx = mv_fps * math.cos(launch_angle_rad)
    vy = mv_fps * math.sin(launch_angle_rad)

    # Wind drift calculation (separate 2D problem in horizontal plane)
    z = 0.0   # Crosswind deflection
    vz = 0.0  # Crosswind velocity component

    # Line of sight: from scope (at height h) to zero point
    # LOS slope: the scope is adjusted so LOS hits where PRIMARY bullet lands at zero_range
    los_slope = -scope_height_ft / zero_range_ft  # Simplified: assumes bullet at ~0 height at zero

    t = 0.0
    results = []
    next_record = 0.0

    while x <= max_range_ft:
        # Record at intervals
        if x >= next_record:
            # Scope line of sight: starts at scope_height, slopes down to target
            los_y = scope_height_ft + los_slope * x
            drop = y - los_y
            v = math.sqrt(vx**2 + vy**2)
            results.append((x, drop, z, v, t))
            next_record += record_interval_ft

        # Velocity magnitude
        v = math.sqrt(vx**2 + vy**2)
        if v < 100:  # Bullet too slow
            break

        # Drag deceleration
        mach = v / sos
        cd = get_cd(mach, model)
        drag_accel = rho_ratio * v * cd / bc * 0.00071054  # Magic constant for fps/lb units

        # Acceleration components
        ax = -drag_accel * vx
        ay = -drag_accel * vy - GRAVITY

        # Wind drift: treat as drag on (vz - wind_fps)
        vz_rel = vz - wind_fps
        az = -drag_accel * vz_rel if abs(vz_rel) > 0.1 else 0

        # Euler integration
        vx += ax * dt
        vy += ay * dt
        vz += az * dt
        x += vx * dt
        y += vy * dt
        z += vz * dt
        t += dt

    return results


def find_zero_angle(
    bc: float,
    model: str,
    mv_fps: float,
    zero_range_ft: float,
    scope_height_ft: float,
    temp_f: float,
    pressure_inhg: float,
) -> float:
    """Find launch angle that zeros at given range. Returns angle in radians."""
    # Binary search for angle where bullet height = 0 at zero range
    low, high = 0.0, 0.05  # 0 to ~3 degrees

    for _ in range(50):
        mid = (low + high) / 2
        traj = simulate_trajectory(
            bc, model, mv_fps, mid, scope_height_ft, zero_range_ft,
            temp_f, pressure_inhg, 0, zero_range_ft + 10
        )

        # Find drop at zero range - we want drop = 0 (bullet on LOS)
        for r, drop, _, _, _ in traj:
            if abs(r - zero_range_ft) < 1:
                if drop > 0:  # Bullet above LOS, reduce angle
                    high = mid
                else:         # Bullet below LOS, increase angle
                    low = mid
                break
        else:
            low = mid

    return (low + high) / 2


def find_equivalent_zero(
    bc: float,
    model: str,
    mv_fps: float,
    launch_angle_rad: float,
    scope_height_ft: float,
    zero_range_ft: float,
    temp_f: float,
    pressure_inhg: float,
    max_range_ft: float,
) -> float | None:
    """
    Find the far zero distance where trajectory crosses LOS from above.
    Returns distance in yards, or None if never crosses.
    """
    # Simulate at 1-yard resolution for accurate crossing detection
    traj = simulate_trajectory(
        bc, model, mv_fps, launch_angle_rad, scope_height_ft, zero_range_ft,
        temp_f, pressure_inhg, 0, max_range_ft,
        record_interval_ft=3.0  # Every yard
    )

    # Find all LOS crossings
    crossings = []
    for i in range(1, len(traj)):
        r1, d1, _, _, _ = traj[i - 1]
        r2, d2, _, _, _ = traj[i]
        if d1 * d2 < 0:  # Sign change
            t = abs(d1) / (abs(d1) + abs(d2))
            cross_range = r1 + t * (r2 - r1)
            direction = "up" if d1 < 0 else "down"
            crossings.append((cross_range / 3.0, direction))  # yards

    # Return the first above-to-below crossing (far zero)
    for dist, direction in crossings:
        if direction == "down":
            return dist

    return None


def main():
    scope_height_ft = SCOPE_HEIGHT_IN / 12.0
    zero_range_ft = ZERO_DISTANCE_YD * 3.0
    wind_fps = WIND_MPH * 5280 / 3600
    max_range_ft = 1001 * 3  # 1001 yards to ensure 1000 is captured

    # Find zero angle for primary load
    zero_angle = find_zero_angle(
        PRIMARY["bc"], PRIMARY["model"], PRIMARY["mv_fps"],
        zero_range_ft, scope_height_ft, TEMP_F, PRESSURE_INHG
    )

    all_loads = [PRIMARY] + SECONDARY

    for load in all_loads:
        print(f"\n{'=' * 60}")
        print(f"{load['name']}: {load['weight_gr']}gr, BC={load['bc']} ({load['model']}), MV={load['mv_fps']} fps")
        print(f"{'=' * 60}")

        # Simulate with primary's zero angle
        traj = simulate_trajectory(
            load["bc"], load["model"], load["mv_fps"],
            zero_angle, scope_height_ft, zero_range_ft,
            TEMP_F, PRESSURE_INHG, wind_fps, max_range_ft
        )

        # Print table
        print(f"{'Range':>6}  {'Drop':>8}  {'Drop':>8}  {'Wind':>8}  {'Vel':>6}  {'TOF':>6}")
        print(f"{'(yd)':>6}  {'(in)':>8}  {'(MOA)':>8}  {'(in)':>8}  {'(fps)':>6}  {'(s)':>6}")
        print("-" * 60)

        for range_ft, drop_ft, wind_ft, vel, tof in traj:
            range_yd = range_ft / 3
            drop_in = drop_ft * 12
            wind_in = wind_ft * 12
            # MOA: 1 MOA = 1.047" per 100 yards
            drop_moa = drop_in / (range_yd * 1.047 / 100) if range_yd > 0 else 0
            print(f"{range_yd:6.0f}  {drop_in:8.2f}  {drop_moa:8.2f}  {wind_in:8.2f}  {vel:6.0f}  {tof:6.3f}")

        # Find equivalent zero for non-primary loads
        if load != PRIMARY:
            eq_zero = find_equivalent_zero(
                load["bc"], load["model"], load["mv_fps"],
                zero_angle, scope_height_ft, zero_range_ft,
                TEMP_F, PRESSURE_INHG, max_range_ft
            )
            if eq_zero:
                print(f"\n>>> Equivalent zero: {eq_zero:.1f} yards")
            else:
                print(f"\n>>> No equivalent zero found (bullet never crosses line of sight)")


if __name__ == "__main__":
    main()
