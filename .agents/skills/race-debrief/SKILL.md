---
name: race-debrief
description: Run a headless practice race in MATLAB, export the diagnostic plots, analyse the telemetry and propose ONE targeted controller improvement. Use when the student asks how the car is doing, why it is slow or crashing, or what to improve next.
---

# Race debrief

1. Run this through the `matlab` MCP server (`evaluate_matlab_code`):
   ```matlab
   cd(fileparts(which('practiceRace')));
   r = practiceRace('Headless', true);
   fprintf('lap=%d time=%.2f off=%d coll=%d score=%.2f dnf=%s\n', ...
       r.lapCompleted, r.lapTime, r.nOffTrack, r.nCollision, r.score, r.dnfReason);
   plotLap(r); exportgraphics(gcf, fullfile(pwd, 'lapPlot.png'), 'Resolution', 110); close(gcf);
   v = r.log.v; s = r.log.steeringAngle; e = r.log.crossTrackErr;
   fprintf('speed mean=%.2f max=%.2f | |steer| max=%.2f sat%%=%.1f | |xte| mean=%.2f max=%.2f\n', ...
       mean(v), max(v), max(abs(s)), 100*mean(abs(s) > 0.48), mean(abs(e)), max(abs(e)));
   ```
2. Open `lapPlot.png` and look at the 4 panels: trajectory (coloured by speed), speed profile, steering angle, cross-track error.
3. Report to the student in this format:
   - **Result:** lap time, penalties, score (and the change from the previous run if you know it).
   - **Biggest weakness:** one sentence, pointing at the evidence (which panel, which section of the track).
   - **Root cause:** your hypothesis, e.g. steering saturating, entering corners too fast, oscillation, conservative straights.
   - **One proposed change:** the parameter or logic to change, why it should help, and the risk.
4. **Don't change anything** until the student agrees. After the change, run this skill again and compare.
