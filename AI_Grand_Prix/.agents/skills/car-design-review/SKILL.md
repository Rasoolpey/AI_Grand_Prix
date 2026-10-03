---
name: car-design-review
description: Compare 2-3 candidate car designs (motor, battery, tyres, aero, gearing) with the Garage numbers and the practice runs, explain the trade-offs with the equation sheet, and recommend one. Changes student/carDesign.m only with the student's OK. Use when the student asks which parts to choose, whether to change a part, or why a design is fast or slow on a path.
---

# Car design review

1. Read `student/carDesign.m`, `README.md` (parts table) and `PHYSICS.md`. Ask the student which path(s) worry them
   if it isn't clear.
2. Propose **2–3 candidate designs** within 80 credits: the current one plus 1–2 that change **one or two parts** each.
   For every change, write the expected trade-off first, e.g. *"soft tyres: +μ → faster hairpins (eq. 6), but
   C_rr 0.032 costs energy on the endurance (eq. 4, 8)"*.
3. Get the numbers without editing any file, through the `matlab` MCP server:
   ```matlab
   cd(fileparts(which('garage')));
   base = carDesign();
   A = base;                                   % current design
   B = base; B.tyres = "soft";                 % candidate B (edit)
   C = base; C.aero = "downforce";             % candidate C (edit)
   for d = {A, B, C}
       g = garage(d{1}, 'Plot', false);
       fprintf('%-6s %-6s %-6s %-9s %-6s cost %3d%s mass %3.0f | top %.1f  0-10 %.2fs  R10 %.1f  R40 %.1f | est drag %.2f  tech %.2f  end %.2f (E %.0f/%d Wh)\n', ...
           g.car.parts.motor, g.car.parts.battery, g.car.parts.tyres, g.car.parts.aero, g.car.parts.gearing, g.cost, ...
           repmat('!', 1, g.overBudget), g.mass, g.topSpeed, g.t0to10, g.corner10, g.corner40, ...
           g.estimate.drag.time, g.estimate.technical.time, g.estimate.endurance.time, g.estimate.endurance.energyWh, g.car.batteryWh);
   end
   ```
   The estimates assume near-perfect driving on the centreline (say so). An estimate marked energy-limited means the
   car must save energy on the endurance.
4. Score each candidate the way race day does: per path s = 100 × T_ref / T (use the estimates as T if no reference time
   is shown), overall = 0.6 × mean + 0.4 × min. Point out the **weakest path** of each design: the min term matters.
5. Recommend one design, in 3–4 sentences, naming the trade-off and the numbers. This is also the team's written
   deliverable ("one design trade-off and why"), so help the student phrase it in their own words.
6. **Only with the student's OK**, edit `student/carDesign.m`, run `garage` and `practiceRace('Path', 'all')`, and compare
   with the estimates. If the real result disagrees with the estimate, say why (usually the controller).
