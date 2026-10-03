# AI Grand Prix — Design Specification (draft v1)

> Status: **proposal for Rasool to approve**. Nothing in the simulator has been changed yet.
> Goal (Rasool): students design **their car and its control system together**; they **see what they are designing**; the challenge is
> **fairly complicated, but not too complicated**; the **math behind the systems** is visible and learned briefly.

---

## 1. The idea in one paragraph

Each student (or team) builds a small **electric race car** from parts, under a **budget**. Every part changes the physics, and every
part comes with **one short equation** shown on screen. The car then has to complete **five paths**, each stressing a different part
of the design. A specialist car wins one path and loses overall; the winner is the best **all-rounder**. The same equations that
describe the car also help the student write a better controller (for example, the fastest safe cornering speed comes straight from
the tyre equation). The agent in Antigravity does the coding and runs MATLAB; the student makes the engineering decisions.

---

## 2. What the student designs

### 2.1 The car: five choices, three options each

| Part | Options | What it changes | Cost (credits) |
|---|---|---|---|
| **Motor** | 3 kW · 5 kW · 8 kW | Power → acceleration and top speed. Heavier when bigger | 10 · 20 · 35 |
| **Battery** | 60 Wh · 90 Wh · 130 Wh | Energy for the endurance path. Heavier when bigger | 10 · 18 · 30 |
| **Tyres** | Hard · Medium · Soft | Grip μ (cornering, braking) vs rolling resistance (energy) | 5 · 12 · 20 |
| **Aero kit** | None · Low-drag · High-downforce | Downforce (more grip at speed) vs drag (top speed, energy) | 0 · 10 · 20 |
| **Gearing** | Short · Medium · Long | Pulling force at low speed vs top speed | free (a tuning choice) |

**Budget: 80 credits.** The most expensive parts add up to 105, so students must choose where to spend. Mass is not chosen; it follows
from the parts. All numbers are starting values, to be tuned in the balance check (§7).

<details><summary>Starting parameter values (for implementation)</summary>

| Part | Option | Values |
|---|---|---|
| Chassis (fixed) | — | 70 kg, wheelbase L = 1.0 m, max steer 0.5 rad, steer rate 1.5 rad/s, drivetrain efficiency η = 0.85 |
| Motor | 3 / 5 / 8 kW | mass 8 / 12 / 18 kg |
| Battery | 60 / 90 / 130 Wh | mass 5 / 8 / 12 kg |
| Tyres | Hard / Medium / Soft | μ = 0.9 / 1.1 / 1.3; C_rr = 0.010 / 0.013 / 0.018 |
| Aero | None / Low-drag / High-downforce | C_D·A = 0.35 / 0.30 / 0.50 m²; C_L·A = 0 / 0.3 / 1.2 m²; mass 0 / 2 / 4 kg |
| Gearing | Short / Medium / Long | top speed limit 14 / 18 / 22 m/s; max wheel force 1.3 / 1.0 / 0.8 × (base 600 N) |
| Air | — | ρ = 1.2 kg/m³, g = 9.81 m/s² |

</details>

### 2.2 The controller
Same idea as today (`student/controller.m`): each step it receives the car's state and the track ahead, and returns throttle and
steering. **New:** it also receives **`obs.car`**, the car the student built (mass, μ, power, downforce…), and **`obs.battery`**
(energy left). A controller that uses its own car's numbers drives better, and that is the bridge between design and control.

---

## 3. The math (what students see, briefly)

Six equations, one per idea. Each one appears **next to the part it belongs to** in the Garage (§5), and in a one-page `PHYSICS.md`.

| # | Idea | Equation | What it teaches |
|---|---|---|---|
| 1 | Newton's 2nd law along the track | **m·dv/dt = F_drive − F_drag − F_roll − F_brake** | Every part either pushes or holds back |
| 2 | Motor: power limit | **F_drive ≤ min( P / v , F_gear )** | Strong pull at low speed, fades at high speed |
| 3 | Air drag and downforce | **F_drag = ½ ρ C_D A v²**, **F_down = ½ ρ C_L A v²** | Both grow with v²: aero matters only when fast |
| 4 | Rolling resistance | **F_roll = C_rr · m · g** | Sticky tyres and heavy cars cost energy |
| 5 | Tyre grip (friction circle) | **√(F_x² + F_y²) ≤ μ (m g + F_down)** | Braking and turning share one grip budget |
| 6 | Cornering speed limit | **v_max = √( μ (g + F_down/m) / κ )** (κ = curvature) | The fastest safe speed in a corner, from the tyres |
| + | Steering (bicycle model) | **dθ/dt = v · tan(δ) / L** | How steering angle turns into turning |
| + | Battery | **dE/dt = − F_drive · v / η** | Speed costs energy; an empty battery stops the car |

What the simulator does with them: each 0.02 s step it computes the forces (1–4), limits them by the friction circle (5), and integrates
speed, position, heading and battery. If the controller asks for more grip than the tyres have, the car **understeers**: it turns less
than commanded and runs wide, which students can see.

---

## 4. The paths

Each path stresses one part of the design. **Rule 1: everyone must finish every path.**

| Path | Shape | Stresses | Finish rule | What wins here |
|---|---|---|---|---|
| **1. Drag strip** | 150 m straight, stop box at the end | Motor, gearing, mass | Stop inside the box | Power-to-weight, short gearing |
| **2. Slalom** | Cones every 15 m | Tyres, steering, controller | All gates in order (missed gate = +2 s) | Grip, light car, smooth steering |
| **3. Technical circuit** | Tight corners, short straights | Tyres, controller | One valid lap | Grip and good corner speeds (eq. 6) |
| **4. Endurance** | 6 laps of a fast circuit | Battery, aero drag, tyres | All laps before the battery is empty | Efficiency: battery vs drag vs speed |
| **5. Unseen track** | Revealed on race day | Everything | One valid lap | A controller that generalises |

Why this produces trade-offs: soft tyres win paths 2–3 but cost energy in path 4; a big motor wins path 1 but adds mass (paths 2–3) and
drains the battery (path 4); downforce helps paths 3 and 5 but its drag hurts paths 1 and 4.

---

## 5. What students see (the "proper look")

### 5.1 The Garage — `garage` (new)
A MATLAB figure that redraws every time the student changes `student/carDesign.m`:

```
┌───────────────────────────────────────────────────────────────────────────────┐
│  YOUR CAR: "Team Name"                              BUDGET  ███████████░ 72/80│
│                                                                               │
│         ┌──────────┐  ← front wing (grows with the aero kit)                   │
│      ▐██│          │██▌  ← tyres coloured by compound (red soft · yellow      │
│         │  MOTOR   │       medium · white hard, like F1)                       │
│         │ BATTERY  │  ← boxes sized by kW / Wh                                 │
│      ▐██│          │██▌                                                        │
│         └──────────┘  ← rear wing                                             │
│                                                                               │
│  SPEC SHEET               STRENGTHS (radar)          THE PHYSICS              │
│  Mass        96 kg        Acceleration ▓▓▓▓░         F = P / v                 │
│  Power/mass  52 W/kg      Cornering    ▓▓▓░░         v = √(μ(g+F↓/m)/κ)        │
│  Top speed   18.0 m/s     Top speed    ▓▓▓▓░         F_drag = ½ρC_DAv²         │
│  Corner g    1.1 g        Range        ▓▓░░░         dE/dt = −F·v/η            │
│  Range       ~5.2 laps    Efficiency   ▓▓▓░░                                   │
└───────────────────────────────────────────────────────────────────────────────┘
```
- **Top-down car drawing** that changes with the parts (wing size, tyre colour, motor and battery boxes).
- **Spec sheet** computed from the equations (top speed from power vs drag, corner g from μ and downforce, range from battery vs
  energy per lap).
- **Strengths radar** across the five paths' needs, so the trade-off is visible before racing.
- **Budget bar** that turns red when over budget (an over-budget car cannot race).

### 5.2 The race view (existing visualizer, extended)
The current F1-style track view gets a **HUD**: speed, throttle/brake, **battery %**, and a small **friction-circle dot** (g-g diagram)
showing how much tyre grip is in use. When the dot hits the circle, the car is at the limit; past it, it understeers.

### 5.3 Race day
All qualified cars shown together as **ghost cars** in team colours with names, a **leaderboard** per path, and the overall standings.

---

## 6. Scoring (to approve)

- Each path: **sᵢ = 100 × T_ref,i / Tᵢ** (time including penalties), capped at 120. `T_ref` is fixed per path before the event (the time
  of a reference "balanced" car), so a score never depends on who else entered.
- **Overall = 0.6 × mean(sᵢ) + 0.4 × min(sᵢ).** The weakest-path term rewards balance.
- **Did not finish a path → sᵢ = 0** there. **[?] Decide:** is the car also ranked below every car that finished all paths
  (proposed), or fully disqualified?
- Ties: the higher min(sᵢ) wins.

---

## 7. Balance check (before release)

Tune the numbers in §2.1 until:
- at least **three different designs** (power-heavy, grip-heavy, balanced) finish within about 5 % of each other overall;
- **no design wins every path**;
- the **baseline design + baseline controller** finishes all five paths (slowly);
- the endurance path is impossible at full throttle with the small battery (so energy management matters).

---

## 8. Files (when approved)

| File | Who | What |
|---|---|---|
| `student/carDesign.m` | student | Five choices + team name and colour |
| `student/controller.m` | student | As today, plus `obs.car` and `obs.battery` |
| `garage.m` | student runs | The Garage figure (§5.1) |
| `practiceRace.m` | student runs | Gains a `'Path'` option: `practiceRace('Path','slalom')` |
| `PHYSICS.md` | student reads | One page: the equations of §3 with one picture each |
| `simulator/Vehicle.m`, `Track.m`, `RaceSimulation.m`, `Visualizer.m` | do not modify | New physics, path types, HUD |
| `instructor/race/` | instructor | Final tracks, evaluator (worker processes + timeouts), live race view |

The agent skill `race-debrief` and `AGENTS.md` are updated to know the paths and the physics.

---

## 9. Decisions needed from Rasool

1. Is this **scale and part list** right (5 parts × 3 options, 80-credit budget), or do you want more or fewer parts?
2. Are these **five paths** right?
3. **DNF rule:** zero on that path and ranked below all finishers, or disqualified?
4. **Ghost cars** (no contact) on race day? (Recommended.)
5. **Teams or individuals**, and how long is Part 2? (This sets how many paths are realistic.)
