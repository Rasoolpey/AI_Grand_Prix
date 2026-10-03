# tracks/ — Race Track Data

This folder contains the practice track generator and its saved data file.

## Files

| File | Description |
|---|---|
| `createPracticeTrack.m` | Generates the practice circuit (~325 m). Run automatically by `practiceRace` if needed. |
| `practiceTrack.mat` | Auto-generated on first `practiceRace` run. |

The final race uses a different track that is **not** in this folder; it is revealed on the day.

## Generating Track Files

```matlab
practiceRace    % generates practiceTrack.mat automatically if missing
```

## Track Format

Track generators return a `trackData` struct:

| Field | Size | Description |
|---|---|---|
| `centreline` | N×2 | [x, y] centreline waypoints (m) |
| `width` | 1×1 | Track width (m) |
| `normals` | N×2 | Unit normals pointing left of travel |
| `leftBoundary` | N×2 | Left track edge |
| `rightBoundary` | N×2 | Right track edge |
| `cumDist` | N×1 | Cumulative arc-length (m) |
| `lapLength` | 1×1 | Total lap length (m) |
| `startFinishLine` | 1×4 | [x1 y1 x2 y2] finish line segment |
| `name` | string | Track name |
