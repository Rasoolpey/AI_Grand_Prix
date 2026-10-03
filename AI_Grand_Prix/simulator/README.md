# simulator/ — physics and rules

```
╔══════════════════════════════════════════╗
║  DO NOT MODIFY ANY FILE IN THIS FOLDER  ║
╚══════════════════════════════════════════╝
```

Every team uses the same simulator: the competition is about your **design** and your **controller**.

| File | What it does |
|---|---|
| `parts.m` | the parts catalogue and the budget |
| `buildCar.m` | turns `carDesign()` into the car's numbers; rejects unknown parts and over-budget cars |
| `physics/` | the equation sheet as functions: `driveForce` (eq. 2), `roadForces` (eqs. 3, 4, 9), `gripLimit` (eq. 5), `cornerSpeed` (eq. 6), `stepCar` (one time step, eqs. 1–9) |
| `RaceSimulation.m` | the race loop: calls `controller(obs, config)` every 0.02 s, applies the rules (checkpoints, penalties, DNF) |
| `RacePath.m`, `buildPath.m`, `+road/` | the roads: built from straights, corners, chicanes and wet patches |
| `benchmarkTime.m` | the estimated benchmark time (same physics, near-perfect driving on the centreline) |
| `Visualizer.m` | the race view and HUD |

You may **call** these functions from your controller, e.g. `cornerSpeed(obs.car, kappa)`. The equations are explained in
[../PHYSICS.md](../PHYSICS.md); the rules in [../README.md](../README.md).
