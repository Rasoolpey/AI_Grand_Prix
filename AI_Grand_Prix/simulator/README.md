# simulator/ — Race Simulator

```
╔══════════════════════════════════════════╗
║  DO NOT MODIFY ANY FILE IN THIS FOLDER  ║
╚══════════════════════════════════════════╝
```

These files implement the fixed simulation environment. All teams share **identical physics** — the competition is about controller quality, not simulator hacking.

## Files

| File | Description |
|---|---|
| `Vehicle.m` | 2D kinematic bicycle model. Enforces all physical limits. |
| `Track.m` | Track representation, boundary queries, start/finish detection. |
| `RaceSimulation.m` | Fixed-timestep simulation loop. Calls `controller(obs, config)` each step. |
| `Visualizer.m` | Live 2D animation window. |

## Vehicle Physics (fixed for all teams)

| Parameter | Value |
|---|---|
| Max speed | 10 m/s (36 km/h) |
| Max acceleration | 3 m/s² |
| Max braking | 6 m/s² |
| Max steering angle | 0.5 rad (~28°) |
| Max steering rate | 1.0 rad/s |
| Wheelbase (bicycle model) | 0.5 m |
| Timestep | 0.02 s (50 Hz) |

## What You CAN Control

Only these files in `student/`:
- `controller.m` — your autonomous control logic
- `robotConfig.m` — tuning hyperparameters

The `obs` struct your controller receives, and the `command` struct it must return, are fully documented inside `student/controller.m`.
