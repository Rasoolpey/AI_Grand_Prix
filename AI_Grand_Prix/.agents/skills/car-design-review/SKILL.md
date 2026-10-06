---
name: car-design-review
description: Improve the student's car design (motor, battery, tyres, aero, gearing). Finds the weakest path, proposes 2-3 candidate designs within 80 credits (or uses the student's own), gets the Garage numbers for each, scores them the way race day does, and explains each trade-off with the equation sheet. The student picks; then this skill edits student/carDesign.m and tests the new car on all four paths. Use when the student asks to improve their car, which parts to choose, whether to change a part, or why a design is fast or slow on a path.
---

# Car design review

You suggest and test; the student picks. Keep every reply short and plain.

1. **Read** `student/carDesign.m`, `README.md` (parts table) and `PHYSICS.md`. If you have no results for the current car
   yet, run the four-path test from `AGENTS.md` first.

2. **Candidates.** If the student named designs to compare, use those. Otherwise propose **2–3 yourself**, each changing
   **one or two parts** of the current car and aimed at the weakest path, within 80 credits. For each, one line on what it
   should gain and what it costs (e.g. *soft tyres: more grip, faster corners (eq. 6); more rolling loss, more energy
   (eqs. 4, 8)*).

3. **Get the numbers** without editing any file, through the `matlab` MCP server. Set `B` and `C` to the candidates:
   ```matlab
   cd(fileparts(which('garage')));
   base = carDesign();
   A = base;                                   % current car
   B = base; B.tyres = "soft";                 % candidate B
   C = base; C.motor = "5.5kW";                % candidate C (or delete this line)
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
   endurance. Path order: drag, technical, endurance, mud. Scores use the race-day rule: s = min(120, 100 × T_ref / T),
   overall = 0.6 × mean + 0.4 × min.

4. **Report, briefly:** one small table (each candidate's parts, cost, estimated score per path, overall, weakest path),
   then one line per candidate: what it gains, what it costs, which equation explains it. Say that these are
   **estimates** with a near-perfect driver: the real gain also depends on the controller. End with:
   *"Which one should I build: A, B or C?"* If they ask which you would pick, say so, and why.

5. **Build it** when they choose: edit `student/carDesign.m` (parts only; keep their team name and colour), then run the
   four-path test from `AGENTS.md` and show before → after. Ask: keep it or undo it? Then remind them to race their ghost
   in MATLAB, `practiceRace('Path', 'all')`: if the overall beats their best, it becomes their new best model.
