# submissions/ (instructor, race day)

Unpacked team submissions live here; everything except this README is git-ignored.

## Race day in one command: `finalRace`

Each team hands in its **best model**: `best_model/<team>.zip`, saved automatically by `practiceRace('Path', 'all')`
whenever their overall score beat their best (`submitCar` checks it and adds their engineering log). Put every team's zip
in one folder (or the same files unzipped in sub-folders), then:

```matlab
cd instructor/race; addpath(pwd, fullfile(pwd, 'controllers'), fullfile(pwd, 'tests')); setupPaths();
F = makeFinals(<secret seed>);          % once: build + verify the race-day paths, measure T_ref (private, git-ignored)
finalRace('<folder with the models>')   % scrutineering, then the four races on the projector, then the standings
```

- **Names on screen** come from `car.team` inside each model, not from the file name. Two models with the same name are
  shown as `Name` and `Name (2)`.
- **Scrutineering:** every model is checked (legal car, the code scan in `scanModelCode`) and driven on every path on this
  computer, one after the other. Flagged code is not raced until you have read it: `finalRace(folder, 'AllowFlagged', true)`.
  A controller that errors gets a DNF on that path; one that computes for more than `'RunLimit'` seconds (60) on a path too.
- **The races:** every car on the track at once (ghost cars: no contact), a 3-2-1 countdown, a live running order, and a
  pace of about `'Seconds'` (12) on screen per race, set by the reference time. Cars still running after twice that are
  fast-forwarded. Each race ends with its results; then the overall standings and awards.
- **Results** are saved in `results/final_<date>_<time>/` (`runs.mat`, `results.csv`). Replay without re-simulating:
  `raceDay('Out', '<that folder>')`; tables only: `raceDay('Out', '<that folder>', 'Static', true)`.
- **Rehearsal** without race-day paths: `finalRace(folder, 'Paths', "practice")`. With fake teams:
  `inbox = makeRehearsal(10); delete(fullfile(inbox, 'submission_Team02.zip')); finalRace(inbox)` (Team02 loops forever
  on purpose: see below).
- **A controller that loops forever** freezes the scrutineering on its own line (MATLAB cannot interrupt it in-process):
  press Ctrl+C, take that file out of the folder, run again.

## Full isolation (the older pipeline)

Each team in its own MATLAB process with a wall-clock limit, which also contains infinite loops:

```matlab
T = collectSubmissions('<folder with the models>');   % unzip every *.zip here, scan the code
[S, R] = qualify();                                   % every team, every path, own MATLAB process + wall-clock limit
raceDay                                               % the races, path leaderboards, standings
raceDay('Static', true)                               % fallback: tables only
```

Each `<team>/` folder holds the team's `carDesign.m`, `controller.m`, `robotConfig.m`, `manifest.json` and log. Flagged
code (system calls, file writes, eval, ...) is listed by `collectSubmissions` and skipped by `qualify` until you have read
it and pass `'AllowFlagged', ["TeamName"]`. Separate processes contain crashes and hangs; they are not a security sandbox.

Rehearsal with fake teams: `inbox = makeRehearsal(30); collectSubmissions(inbox); qualify(); raceDay('SaveFrames', 'frames')`.
