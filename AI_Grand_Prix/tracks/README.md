# tracks/ — practice paths

| File | Path |
|---|---|
| `practiceDrag.m` | C1 drag strip: 150 m, then a 10 m stop box |
| `practiceTechnical.m` | C2 technical circuit, 1 lap |
| `practiceEndurance.m` | C3 endurance, 5 laps, with a hill |
| `practiceMud.m` | C4 muddy road, 1 lap: three mud sections (grip x 0.6, rolling resistance x 4) and a hill |
| `practiceWet.m` | a short loop with one wet patch (extra practice, not scored) |
| `loadPath.m` | `course = loadPath("technical")`: "drag", "technical", "endurance", "mud", "wet" |
| `practiceReference.m` | the reference times (T_ref) used for your practice score |

Each path is a list of road pieces (`road.straight`, `road.corner`, `road.chicane`, `road.surface`, `road.mud`) built by `buildPath`.
The race-day paths are **new layouts** of the same kinds of pieces; they are not in this folder.
