# 🏎️ AI Grand Prix — Design. Drive. Race.
### Agentic AI for Electrical Engineering with MATLAB

> **Build a small electric race car from parts, under a budget, then write its driver with your AI agent.**

You work in pairs (solo is fine when pairing isn't practical). Your car must finish **every path**, and each path stresses
a different part of the design. Every part comes with **one short equation** ([PHYSICS.md](PHYSICS.md)), and the same
equations make your controller better. The winner is the best **all-rounder**.

---

## 🎯 Your mission

1. **Design** the car: choose 5 parts within **80 credits** (`student/carDesign.m`). Check it in the **Garage**.
2. **Drive** it: improve the controller with your agent (`student/controller.m`, `student/robotConfig.m`).
3. **Test** on the practice paths, read the lap report, change **one thing at a time**.
4. **Explain** one design trade-off you made, with numbers (3–4 sentences).
5. **Submit** before the code freeze (`submitCar`).

On race day every car runs the **final paths** (same kind of paths, new layouts you have not seen). All cars appear
together on the projector in a recorded broadcast.

---

## 🧰 The parts (budget 80 credits)

| Part | Option A | Option B | Option C | What it changes |
|---|---|---|---|---|
| Motor | `"2kW"` · 7 kg · 10 | `"3.5kW"` · 11 kg · 20 | `"5.5kW"` · 16 kg · 35 | acceleration (P in eq. 2) |
| Battery | `"45Wh"` · 5 kg · 10 | `"70Wh"` · 8 kg · 18 | `"100Wh"` · 12 kg · 30 | energy for the endurance (eq. 8) |
| Tyres | `"hard"` μ 0.9, C_rr 0.012 · 5 | `"medium"` μ 1.1, C_rr 0.020 · 12 | `"soft"` μ 1.3, C_rr 0.032 · 20 | grip vs rolling loss (eqs. 4–6) |
| Aero kit | `"none"` C_DA 0.35 · 0 | `"lowdrag"` C_DA 0.30, C_LA 0.3 · 2 kg · 10 | `"downforce"` C_DA 0.50, C_LA 1.2 · 4 kg · 20 | drag vs downforce (eqs. 3, 6) |
| Gearing | `"short"` v_gear 14 m/s, F_gear 800 N | `"medium"` 17 m/s, 560 N | `"long"` 20 m/s, 380 N | pull from standstill vs top speed (eq. 2) · free |

Chassis 70 kg. You cannot afford the best of everything, and "the best" depends on the path.

---

## 🛣️ The paths

| Path | What it is | What it tests |
|---|---|---|
| **Drag strip** (`"drag"`) | 150 m straight from a standing start, then a 10 m **stop box** | motor, gearing, mass, braking |
| **Technical circuit** (`"technical"`) | ≈ 370 m, hairpins, a chicane, short straights; 1 lap | tyres, mass, your controller |
| **Endurance** (`"endurance"`) | ≈ 380 m fast circuit with a hill; 5 laps | battery, aero, rolling loss, energy strategy |
| Wet practice (`"wet"`) | a short loop with one wet patch (grip × 0.6–0.8, flagged in advance) | reading the road ahead |

### Finishing, penalties, DNF

| | Finish | Penalties (still a finish) | DNF |
|---|---|---|---|
| Drag strip | cross the line, then **come to rest** | stop past the box (in the run-off): **+3 s** | hit the barrier at the end; over 30 s |
| Circuits | pass **every checkpoint in order**, cross the line forwards, every lap | off-track **+5 s** per incident; barrier **+10 s** per contact | a checkpoint missed (shortcut); stopped > 3 s; time limit; controller error |

An empty battery gives no drive: the car **coasts**, and still finishes if it rolls over the line.

---

## 🏁 Scoring

- Per path: **s = min(120, 100 × T_ref / T)**, where T is your time + penalties and T_ref the reference car's time. DNF = 0.
- **Overall = 0.6 × mean(s) + 0.4 × min(s)**: being good everywhere beats being brilliant once.
  (A specialist scoring 95 / 95 / 20 gets 50; an all-rounder scoring 75 / 75 / 75 gets 75.)
- Ranking: cars that finished every path first, by overall score; then the others by paths completed.
- Awards: 🏁 overall champion · ⚡ best single path · 🧠 best engineering explanation · 🤖 best use of the agent.

---

## 🚀 Commands

```matlab
testMCP                                    % check that everything is installed
garage                                     % your car: drawing, numbers, cost, estimates
practiceRace                               % technical circuit, with animation
practiceRace('Path', 'drag')               % "drag" | "technical" | "endurance" | "wet"
r = practiceRace('Path', 'endurance', 'Headless', true);   % fast, no animation
plotLap(r)                                 % lap report: grip use, speed vs eq. 6, battery, ...
practiceRace('Path', 'all')                % the three paths + your overall score
submitCar                                  % check and hand in (you can resubmit until the freeze)
```

**Garage estimates and the "benchmark" time** come from the equations with near-perfect driving on the centreline.
They are estimates, not limits; your controller decides how close you get (*efficiency = benchmark ÷ your time*).

---

## 📂 Project structure

```
AI_Grand_Prix/
├── README.md  PHYSICS.md  AGENTS.md  AGENT_GUIDE.md
├── garage.m  practiceRace.m  plotLap.m  submitCar.m  testMCP.m
├── student/                 ⭐ your files
│   ├── carDesign.m          the 5 parts
│   ├── controller.m         the driver
│   └── robotConfig.m        tuning values
├── tracks/                  practice paths (read-only)
└── simulator/               physics and rules (DO NOT MODIFY)
```

---

## 📋 Controller interface

```matlab
function command = controller(obs, config)
```

| Input | Meaning |
|---|---|
| `obs.position`, `obs.heading`, `obs.speed`, `obs.steeringAngle` | where the car is, where it points, how fast |
| `obs.previewPoints` | next ~60 centreline points, ~1 m apart: `[x y grade(%) wet(0/1)]` |
| `obs.car` | the car you built: `mass, mu, Crr, power, CdA, ClA, vGear, Fgear, ...` |
| `obs.batteryWh`, `obs.batteryFrac` | energy left |
| `obs.path` | `type, lap, laps, lapsLeft, nextCheckpoint, distanceToFinish, distanceToStop` |
| `obs.time`, `obs.dt`, `obs.trackWidth` | |

| Output | Range |
|---|---|
| `command.throttle` | −1 (full brake) … +1 (full drive) |
| `command.steering` | −1 (full right) … +1 (full left) |

`persistent` variables are allowed (cleared before every run). The simulator's `cornerSpeed(obs.car, kappa)` gives the
safe corner speed of equation 6.

> The final paths are new layouts. A controller tuned to the practice coordinates will fail: **build something that
> generalises.**

---

*Design → Drive → Test → Diagnose → Improve → Race.*
