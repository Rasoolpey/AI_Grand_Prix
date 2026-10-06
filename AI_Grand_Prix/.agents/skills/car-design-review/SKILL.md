---
name: car-design-review
description: Help the student compare their own candidate car designs (motor, battery, tyres, aero, gearing). Collects their candidates and predictions, gets the Garage numbers, scores each design the way race day does, and checks each prediction against the equation sheet. The student chooses the design and writes the trade-off; this skill never picks for them and changes student/carDesign.m only when they say so. Use when the student asks which parts to choose, whether to change a part, or why a design is fast or slow on a path.
---

# Car design review

The student designs the car. Your job is to get them the numbers fast and to test their reasoning against the physics.
The choice and the written trade-off are theirs.

1. **Read** `student/carDesign.m`, `student/engineering_log.md` (sections 1 and 2), `README.md` (parts table) and
   `PHYSICS.md`.

2. **Get the student's candidates and predictions.** Look in the log first. If something is missing, ask for it in **one**
   message and wait:
   - which path worries them most (their weakest path from the baseline run);
   - 1–2 candidate designs, each changing **one or two parts** from their current car;
   - for each candidate, their prediction: what gets better and what gets worse, on which path.

   If they ask for ideas, list the single-part swaps that target their worry path, each with the direction of the effect
   and the equation (e.g. *soft tyres: μ up, so faster corners (eq. 6); C_rr up, so more energy (eqs. 4, 8)*). Give no
   numbers and no favourite yet; let them pick.

3. **Get the numbers** without editing any file, through the `matlab` MCP server. Set `B` and `C` to **their** candidates:
   ```matlab
   cd(fileparts(which('garage')));
   base = carDesign();
   A = base;                                   % current car
   B = base; B.tyres = "soft";                 % the student's candidate B
   C = base; C.motor = "5.5kW";                % the student's candidate C (or delete this line)
   paths = ["drag", "technical", "endurance", "mud"];
   for d = {A, B, C}
       [~, g] = evalc('garage(d{1}, ''Plot'', false)');            % evalc: keep the spec sheet out of the reply
       s = arrayfun(@(p) min(120, 100 * practiceReference(p) / g.estimate.(p).time), paths);
       [~, w] = min(s);
       fprintf('%-6s %-5s %-6s %-9s %-6s cost %3d%s mass %3.0f | 0-10 %.2fs R10 %.1f R40 %.1f | est %.2f / %.2f / %.2f / %.2f s, E %.0f/%d Wh%s | s %.0f / %.0f / %.0f / %.0f  overall %.1f  weakest %s\n', ...
           g.car.parts.motor, g.car.parts.battery, g.car.parts.tyres, g.car.parts.aero, g.car.parts.gearing, g.cost, ...
           repmat('!', 1, g.overBudget), g.mass, g.t0to10, g.corner10, g.corner40, ...
           g.estimate.drag.time, g.estimate.technical.time, g.estimate.endurance.time, g.estimate.mud.time, ...
           g.estimate.endurance.energyWh, g.car.batteryWh, repmat(' (capped)', 1, g.estimate.endurance.capped), ...
           s, 0.6 * mean(s) + 0.4 * min(s), paths(w));
   end
   ```
   `!` after the cost means over budget (that car cannot race). `(capped)` means the estimate had to save energy on the
   endurance. Path order: drag, technical, endurance, mud. Scores use the same rule as race day: s = min(120, 100 × T_ref / T), overall = 0.6 × mean + 0.4 × min.

4. **Report, briefly:**
   - **One table:** each candidate's parts, cost, mass, estimated time per path, endurance energy, path scores, overall
     and weakest path.
   - **Their prediction against the numbers**, candidate by candidate: right, partly right or wrong, and the equation
     that explains it. This is the most useful part of the reply, so make it concrete.
   - **Estimate vs reality:** the estimates assume near-perfect driving on the centreline. If the log (or a run) has the
     current car's measured overall score, put it next to its estimated overall, so they see how much of the gap is the
     car and how much is the driver.
   - **No recommendation** unless they ask for one. End with: *"Which design do you want to race? Write your choice and
     your trade-off in the log, and I'll check it against these numbers."*

   If they ask, copy the numbers into the 📏 table of section 2 of the log. Don't touch their prediction or decision
   lines.

5. **Check their trade-off** once they've written it in the log. Are the numbers right? Is it the right equation? Is a
   cost missing (mass, energy, another path)? Point to the sentence and say what to fix. Don't rewrite it: it is the
   team's written deliverable.

6. **Build it.** The student edits `student/carDesign.m` or tells you to. Then run `garage` and
   `practiceRace('Path', 'all')` and compare with the estimates. If the real result is far from the estimate, say why
   (usually the controller) and ask whether to start the `race-debrief` skill. If the overall beat their best, the run
   was saved as their best model: tell them. If not, their best model is unchanged.
