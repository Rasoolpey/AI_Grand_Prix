# The equation sheet

Every number in the simulator, the Garage and the lap report comes from these nine equations.
In class we use **1, 5, 6, 8 and 9**; the others are here for reference.

Notation: *m* mass (kg), *v* speed (m/s), *g* = 9.81 m/s², ρ = 1.2 kg/m³ air density,
α road angle (grade % = 100·tan α), *N* normal load (N), κ curvature = 1/R (1/m).

| # | Idea | Equation | Which part sets it |
|---|---|---|---|
| **1** | Newton along the road | **m·dv/dt = F_drive − F_drag − F_roll − F_grade − F_brake** | mass: every part except gearing |
| 2 | Motor | F_drive ≤ min(P / v, F_gear), and F_drive = 0 at or above v_gear | motor (P), gearing (v_gear, F_gear) |
| 3 | Air | F_drag = ½ρ·C_DA·v²  ·  F_down = ½ρ·C_LA·v² | aero kit |
| 4 | Load and rolling | N = m·g·cos α + F_down  ·  F_roll = C_rr·N | tyres (C_rr), aero |
| **5** | Friction circle | **√(F_x² + F_y²) ≤ μ·N** | tyres (μ) |
| **6** | Safe corner speed | **v² = μ·g·cos α / (\|κ\| − μ·ρ·C_LA / (2m))** | tyres, aero, mass |
| 7 | Steering | dθ/dt = v·tan δ / L  (L = 1 m) | fixed |
| **8** | Battery | **E ← E − F_drive·v·dt / η**  (η = 0.85; Wh = J / 3600) | battery |
| **9** | Slope | **F_grade = m·g·sin α**  (uphill +, downhill −) | mass |

---

## One sentence each

1. **Newton.** Speed changes only when the forces along the road don't balance; a heavier car changes speed more slowly.
2. **Motor.** At low speed the gearing limits the push (F_gear); higher up, power does (P / v); at v_gear the motor stops pushing. Short gearing pulls hard but tops out early; long gearing is the reverse.
3. **Air.** Drag and downforce both grow with v²: downforce is free grip at speed, but it costs drag on every straight.
4. **Load.** Downforce presses the car into the road (more grip); soft tyres grip more but roll less freely (higher C_rr).
5. **Friction circle.** The tyres have **one** grip budget, shared between braking, driving and turning. Brake hard in a corner and there is less grip left for turning.
6. **Corner speed.** The fastest you can take a corner without sliding. Bigger μ or bigger radius → faster. Downforce helps a lot in fast corners and barely in hairpins.
7. **Steering.** A bicycle model: the tighter the wheel angle, the tighter the turn. If you ask for more turning than the grip allows, the car **understeers** (goes wider than you steered) and has no grip left to brake.
8. **Battery.** Energy is used only while driving, and the faster you go the more you use (drag grows with v²). Empty battery = coasting.
9. **Slope.** Climbing costs force and energy; a 5 % hill on a 95 kg car is ≈ 46 N, about the drag at 15 m/s.

---

## Worked example: equation 6

Soft tyres (μ = 1.3), 95 kg, flat road:

| Corner | No aero kit (C_LA = 0) | Downforce kit (C_LA = 1.2) |
|---|---|---|
| Hairpin, R = 8 m | v² = 1.3 · 9.81 / 0.125 → **10.1 m/s** | v² = 12.75 / (0.125 − 0.0099) → **10.5 m/s** |
| Sweeper, R = 40 m | v² = 12.75 / 0.025 → **22.6 m/s** | v² = 12.75 / (0.025 − 0.0099) → **29.0 m/s** |

**Downforce barely helps in hairpins and helps a lot in fast corners.** Whether that is worth the extra drag depends on the path.

Why the equation has that form: the tyres must supply m·v²·|κ| sideways and can supply μ·(m·g·cos α + ½ρ·C_LA·v²),
so v² appears on both sides.

---

## How to use equation 6 in your controller

1. **Curvature ahead.** For preview points i−2, i, i+2 (≈ 4 m apart), the curvature of the circle through three points
   a, b, c is κ = 2·((b−a) × (c−b)) / (|b−a|·|c−b|·|c−a|).
2. **Corner speed** at each point: `vCorner = cornerSpeed(obs.car, kappa, alpha, muFactor)` (wet points: assume μ × 0.6).
   Keep a margin, e.g. 0.9 × vCorner.
3. **Brake in time.** You can still reach vCorner at a point *d* metres ahead if you are going no faster than
   √(vCorner² + 2·a_brake·d), with a_brake a bit below μ·g. The target speed now is the **smallest** of those over all preview points.
4. **Drive** towards the target with the throttle; the friction circle (eq. 5) is why braking *before* the corner beats braking *in* it.

**Predict, then test:** before your first run, use equation 6 and the Garage to predict your car's corner speed at R = 10 m.
Then watch the HUD's friction-circle dot in that corner: on the circle = at the limit, red = understeer.

---

## Implementation notes (for the curious)

Fixed time step 0.02 s, semi-implicit Euler, no randomness (the same inputs always give the same run). Energy is stored in
joules and shown in Wh. Throttle > 0 drives with `throttle · min(P / max(v, 0.5), F_gear)`; throttle < 0 brakes with
`|throttle| · μN`; both are limited by what the friction circle leaves after turning. The road is 2-D with an elevation
and a grade at every point; closed circuits return to their start height.
