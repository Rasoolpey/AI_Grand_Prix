---
name: race-debrief
description: Run a headless practice race on one path in MATLAB, export the lap report, read grip use, battery and checkpoints, name the limiting factor (power / grip / energy / control) and propose ONE targeted improvement. Use when the student asks how the car is doing on a path, why it is slow, crashing, running out of energy, or what to improve next.
---

# Race debrief

1. Pick the path the student asks about (`"drag"`, `"technical"`, `"endurance"` or `"wet"`; default `"technical"`) and run
   this through the `matlab` MCP server (`evaluate_matlab_code`), with `P` set to that path:
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
2. Open `lapPlot.png`. Six panels: trajectory coloured by **grip use** (x = understeer), **speed vs the eq. 6 corner limit**
   and the benchmark profile, throttle/brake, **battery**, elevation, **friction circle**.
3. Name the **limiting factor**, from the evidence:
   - **power / gearing**: full throttle on straights, speed flat at v_gear or rising slowly; the benchmark is close.
   - **grip**: grip use near 1 in corners, understeer marks, speed at the eq. 6 line; a tyre or aero question.
   - **energy**: battery near 0 before the end, or the controller slowed down to save it; a battery or strategy question.
   - **control**: speed well below the eq. 6 line and the benchmark, braking early or too long, oscillating steering,
     off-track incidents; a controller question (most common).
4. Report to the student:
   - **Result:** time, penalties, total, efficiency (benchmark ÷ total), energy (and the change from the last run if known).
   - **Limiting factor:** one of the four, with the panel and section of the path that shows it.
   - **Root cause:** your hypothesis.
   - **One proposed change:** controller (`controller.m` / `robotConfig.m`) or a part (`carDesign.m`); why it should help
     (name the equation), and the risk on the *other* paths.
5. **Don't change anything** until the student agrees. After the change, run this skill again and compare. Before
   finishing, check all paths: `practiceRace('Path', 'all')`.
