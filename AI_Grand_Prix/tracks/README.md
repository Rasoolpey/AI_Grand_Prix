# tracks/ — practice paths

| File | Path |
|---|---|
| `practiceDrag.m` | C1 drag strip: 150 m, then a 10 m stop box |
| `practiceTechnical.m` | C2 technical circuit, 1 lap |
| `practiceEndurance.m` | C3 endurance, 5 laps, with a hill |
| `practiceWet.m` | a short loop with one wet patch |
| `loadPath.m` | `course = loadPath("technical")` |
| `practiceReference.m` | the reference times (T_ref) used for your practice score |

Each path is a list of road pieces (`road.straight`, `road.corner`, `road.chicane`, `road.surface`) built by `buildPath`.
The race-day paths are **new layouts** of the same kinds of pieces; they are not in this folder.
