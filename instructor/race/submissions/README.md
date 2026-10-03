# submissions/ (instructor, race day)

Unpacked team submissions live here; everything except this README is git-ignored.

## Race-day pipeline

```matlab
cd instructor/race; addpath(pwd, fullfile(pwd, 'controllers'), fullfile(pwd, 'tests')); setupPaths();
F = makeFinals(<secret seed>);                 % build + verify the final paths, measure T_ref (private)
T = collectSubmissions('<shared folder>');      % unzip submission_<team>.zip here, scan the code
[S, R] = qualify();                             % every team, every path, own MATLAB process + wall-clock limit
raceDay                                         % recorded broadcast, path leaderboards, standings
raceDay('Static', true)                         % fallback: tables only
```

Each `<team>/` folder holds the team's `carDesign.m`, `controller.m`, `robotConfig.m` and `manifest.json`
(written by `submitCar`). Flagged code (system calls, file writes, eval, ...) is listed by `collectSubmissions` and skipped
by `qualify` until you have read it and pass `'AllowFlagged', ["TeamName"]`. Separate processes contain crashes and hangs;
they are not a security sandbox.

Rehearsal with fake teams: `inbox = makeRehearsal(30); collectSubmissions(inbox); qualify(); raceDay('SaveFrames', 'frames')`.
