---
name: race-debrief
description: Run a headless practice race on one path in MATLAB, export the lap report, and ask the student what they think limits the car. Then read grip use, battery and checkpoints, name the limiting factor (power / grip / energy / control), compare it with the student's view, and propose ONE targeted improvement for the student to approve, change or reject. Use when the student asks how the car is doing on a path, why it is slow, crashing or running out of energy, or what to improve next.
---

# Race debrief

The student runs the engineering loop. You run the race, read the telemetry and test their diagnosis against the data.
They decide what to change and whether to keep it.

1. Pick the path the student asks about (`"drag"`, `"technical"`, `"endurance"`, `"mud"` or `"wet"`; default: their weakest path
   from `student/engineering_log.md`, else `"technical"`). Run this through the `matlab` MCP server
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

2. **Show the result and ask first.** Give the one-line result (time, penalties, total, efficiency = benchmark ÷ total,
   energy, and the change since the last run if you know it). Tell them the lap report is in `lapPlot.png` (six panels:
   trajectory coloured by **grip use** (x = understeer), **speed vs the eq. 6 corner limit** and the benchmark,
   throttle/brake, **battery**, elevation, **friction circle**). Then ask, in one line:
   *"Open lapPlot.png: what do you think limits the car here (power, grip, energy or control), and which panel shows it?"*
   Wait for the answer. Skip this step if their message already gives a diagnosis, or they say "just tell me".

3. Open `lapPlot.png` yourself and name the **limiting factor** from the evidence:
   - **power / gearing**: full throttle on straights, speed flat at v_gear or rising slowly; the benchmark is close.
   - **grip**: grip use near 1 in corners, understeer marks, speed at the eq. 6 line; a tyre or aero question. On mud
     and wet points the grip is mu x 0.6 (the eq. 6 line drops there): does the driver read `obs.previewPoints(:,4)`?
   - **energy**: battery near 0 before the end, or the controller slowed down to save it; a battery or strategy question.
   - **control**: speed well below the eq. 6 line and the benchmark, braking early or too long, oscillating steering,
     off-track incidents; a controller question (the most common one).

4. **Report to the student**, briefly:
   - **Your diagnosis vs theirs:** the limiting factor, the panel and the section of the path that shows it. Say plainly
     whether you agree with them, and if not, what in the data points the other way.
   - **Root cause:** your hypothesis, marked as a hypothesis.
   - **One change:** if they proposed one, assess theirs first. Otherwise propose one, in `controller.m` / `robotConfig.m`
     or a part in `carDesign.m`: why it should help (name the equation), and the risk on the *other* paths.
   - End with: *"Do you want this change, a different one, or none?"*

5. **Don't change anything** until the student agrees; they may change your proposal. After the change, run this skill
   again, show before → after, and ask whether to **keep or undo** it. If they ask, add the before → after numbers to
   the change log in `student/engineering_log.md` (the 📏 column only). Before finishing, check all paths:
   `practiceRace('Path', 'all')`. A better overall is saved as their best model automatically; say whether it was.
