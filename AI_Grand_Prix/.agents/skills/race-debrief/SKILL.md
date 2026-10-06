---
name: race-debrief
description: Run a practice race on one path in MATLAB, export the lap report, read grip use, speed, battery and checkpoints, name what limits the car (power / grip / energy / control) in plain words, and propose ONE targeted improvement (usually to the controller) for the student to accept or reject; then make it and test it on all four paths. Use when the student asks to improve the driver or the controller, how the car is doing on a path, why it is slow, crashing or running out of energy, or what to improve next.
---

# Race debrief

You find what limits the car and fix it one change at a time; the student says yes or no. Keep every reply short and plain.

1. Pick the path the student asks about (`"drag"`, `"technical"`, `"endurance"`, `"mud"` or `"wet"`; default: their weakest
   path from the latest four-path results, else `"technical"`). Run this through the `matlab` MCP server
   (`evaluate_matlab_code`), with `P` set to that path:
   ```matlab
   cd(fileparts(which('practiceRace'))); P = "technical";
   r = practiceRace('Path', P, 'Headless', true, 'Quiet', true);
   fprintf('%s fin=%d time=%.2f pen=%d (off %d, barrier %d, runoff %d) total=%.2f bench=%.2f eff=%.0f%% E=%.1f/%.0fWh dnf=%s\n', ...
       r.pathName, r.finished, r.time, r.penalty, r.nOffTrack, r.nBarrier, r.stopInRunoff, r.totalTime, r.benchmark, ...
       100*r.benchmark/r.totalTime, r.energyUsedWh, r.car.batteryWh, r.dnfReason);
   L = r.log; vc = cornerSpeed(r.car, L.curvature, atan(L.grade/100), L.muFactor);
   fprintf('grip use: mean %.2f, >0.95 for %.0f%% of the time, understeer %d steps | v max %.1f (v_gear %d) | over eq.6 limit %d steps\n', ...
       mean(L.gripUse), 100*mean(L.gripUse > 0.95), sum(L.understeer), max(L.v), r.car.vGear, sum(L.v > vc));
   fprintf('throttle: full %.0f%%, braking %.0f%% | battery left %.0f%% | checkpoints passed %d | laps %s\n', ...
       100*mean(L.throttle > 0.95), 100*mean(L.throttle < 0), 100*r.batteryLeftFrac, r.checkpointsPassed, mat2str(round(r.lapTimes, 2)));
   plotLap(r); exportgraphics(gcf, fullfile(pwd, 'lapPlot.png'), 'Resolution', 110); close(gcf);
   ```

2. Open `lapPlot.png` and name the **limiting factor** from the evidence:
   - **power / gearing**: full throttle on straights, speed flat at v_gear or rising slowly; the benchmark is close.
   - **grip**: grip use near 1 in corners, understeer marks, speed at the eq. 6 line; a tyre or aero question. On mud
     and wet points the grip is mu x 0.6 (the eq. 6 line drops there): does the driver read `obs.previewPoints(:,4)`?
   - **energy**: battery near 0 before the end, or the controller slowed down to save it; a battery or strategy question.
   - **control**: speed well below the eq. 6 line and the benchmark, braking early or too long, oscillating steering,
     off-track incidents; a controller question (the most common one).

3. **Report, briefly:** the one-line result (time, penalties, energy); what limits the car, in plain words, and where you
   see it (the lap report is in `lapPlot.png`: grip use, speed vs the eq. 6 corner limit, throttle/brake, battery,
   elevation, friction circle); then **one proposed change** (usually in `controller.m` or `robotConfig.m`): what it does,
   why it should help (name the equation), and the risk on the other paths. If the student proposed a change, assess
   theirs first. End with: *"Shall I make this change?"*

4. **Make it** only when they agree, then run the four-path test from `AGENTS.md` and show before → after. Ask: keep it or
   undo it? Then remind them to race their ghost in MATLAB, `practiceRace('Path', 'all')`: if the overall beats their best,
   it becomes their new best model. Never hard-code anything about the practice tracks.
