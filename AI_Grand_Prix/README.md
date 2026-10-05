# 🏎️ AI Grand Prix — Design. Drive. Race.
### Agentic AI for Electrical Engineering with MATLAB

> **You are the race engineer. The agent is your pit crew.**

## 🎯 The aim

Build a small electric race car **and the code that drives it**, so that it finishes **every path** as fast as possible,
including race-day layouts you have never seen.

There is **no single best car**. Every part that makes your car better somewhere makes it worse somewhere else, and you
can't afford the best of everything. Your job is to find the **sweet spot** for the paths you'll race, show it with
data, and explain it.

| | |
|---|---|
| **You hand in** | your car (`student/carDesign.m`), your driver (`student/controller.m`, `student/robotConfig.m`) and your engineering log (`student/engineering_log.md`), all with `submitCar` |
| **You are scored on** | your overall score on race day, across three new paths (see *How you're scored*). Two awards are judged from your log: 🧠 best engineering explanation and 🤖 best use of the agent |
| **You will learn** | how to make engineering trade-offs from data, and how to work with an AI agent while you stay the engineer in charge |

You work in pairs (solo is fine when pairing isn't practical). The agent can run MATLAB and write code much faster than
you can. It doesn't make the decisions: **you** do (see *Who does what*).

---

## 🔧 How your car is modelled

The simulator treats your car as **one mass** (a chassis plus your parts) with **bicycle steering** (one steered front
wheel, 1 m wheelbase), driving on a 2-D road that can go up and down hills. Every 0.02 s it does four things:

1. **Steer.** The front wheel turns towards your steering command, at most 1.5 rad/s, up to 0.5 rad (≈ 29°).
2. **Add up the forces along the road.** The motor pushes. Air drag, the tyres' rolling resistance, hills and the brakes
   hold the car back. Speed changes by force ÷ mass (eq. 1).
3. **Check the tyres' grip.** The tyres have **one** grip budget, μ·N, shared by turning, driving and braking (eq. 5).
   If you ask for more turning than the grip allows, the car **understeers**: it runs wide and has no grip left to brake.
4. **Drain the battery** by the energy the motor delivers, divided by the 0.85 efficiency (eq. 8). Braking recovers
   nothing. An empty battery means no drive: the car coasts.

```
                             │  F_down  (aero kit: presses the car onto the road)
                             ↓
  F_drag   (air)   ←──┐ ┌──────────┐
  F_roll   (tyres) ←──┤ │  mass m  │ ──→  F_drive  (motor, through the gearing)
  F_grade  (hill)  ←──┤ └──────────┘
  F_brake  (brake) ←──┘      │
                             ↓  N = m·g·cos α + F_down   (the load on the tyres)

  m·dv/dt = F_drive − F_drag − F_roll − F_grade − F_brake               (eq. 1)
  tyres: one grip budget μ·N, shared by turning, driving and braking    (eq. 5)
```

The simulation has no randomness: the same car and controller always give the same run. Every number comes from nine
short equations in [PHYSICS.md](PHYSICS.md).

---

## 🧰 Your car, part by part

Your car is a **70 kg chassis plus five parts**. The budget is **80 credits**, and the best of everything costs 105, so you
will have to choose. Each part changes one or two numbers in the equations, and each comes with a price: ▲ is what you
gain, ▼ is what you pay.

### Motor: how hard the car can push (eq. 2)

| Option | Power P | Mass | Credits |
|---|---|---|---|
| `"2kW"` | 2.0 kW | 7 kg | 10 |
| `"3.5kW"` | 3.5 kW | 11 kg | 20 |
| `"5.5kW"` | 5.5 kW | 16 kg | 35 |

The push is **F_drive ≤ min(P / v, F_gear)**: at low speed the gearing caps it, and above v = P / F_gear the power does.

- ▲ More power: faster acceleration out of every corner and along every straight.
- ▼ Credits and mass, and a car that accelerates harder uses more energy. At low speed the gearing, not the motor,
  limits the push, so a bigger motor helps most at higher speed.

### Battery: how much energy you can spend (eq. 8)

| Option | Energy | Mass | Credits |
|---|---|---|---|
| `"45Wh"` | 45 Wh | 5 kg | 10 |
| `"70Wh"` | 70 Wh | 8 kg | 18 |
| `"100Wh"` | 100 Wh | 12 kg | 30 |

- ▲ More energy: you can drive the 5-lap endurance at full pace without running dry.
- ▼ Credits and mass, and it only helps if you would otherwise run out. Energy you don't use is dead weight on every
  path.

### Tyres: grip against rolling loss (eqs. 4–6)

| Option | Grip μ | Rolling resistance C_rr | Mass | Credits |
|---|---|---|---|---|
| `"hard"` | 0.9 | 0.012 | — | 5 |
| `"medium"` | 1.1 | 0.020 | — | 12 |
| `"soft"` | 1.3 | 0.032 | — | 20 |

- ▲ Softer: more grip, so faster corners (eq. 6) and harder braking.
- ▼ Softer tyres also roll less freely (F_roll = C_rr·N): more energy per lap, and a little slower in a straight line.

### Aero kit: drag against downforce (eqs. 3, 6)

| Option | Drag area C_D·A | Downforce area C_L·A | Mass | Credits |
|---|---|---|---|---|
| `"none"` | 0.35 m² | 0 | — | 0 |
| `"lowdrag"` | 0.30 m² | 0.3 m² | 2 kg | 10 |
| `"downforce"` | 0.50 m² | 1.2 m² | 4 kg | 20 |

Both drag and downforce grow with v², so aero only matters when you're fast.

- ▲ Downforce presses the car onto the road, giving more grip in **fast** corners but hardly any in hairpins. On the
  starting car, the downforce kit raises the safe speed at R = 40 m from about 22 to 26 m/s, but at R = 10 m only from
  10.5 to 10.9 m/s.
- ▼ More drag on every straight: slower, and much more energy. Note that `"none"` has *more* drag than `"lowdrag"`.

### Gearing: pull against top speed (eq. 2), free

| Option | Top speed v_gear | Most force F_gear | Credits |
|---|---|---|---|
| `"short"` | 14 m/s | 800 N | 0 |
| `"medium"` | 17 m/s | 560 N | 0 |
| `"long"` | 20 m/s | 380 N | 0 |

The motor stops pushing at v_gear, and the gearing passes at most F_gear.

- **Short:** a strong pull from standstill and out of hairpins, but stuck at 14 m/s on the straights.
- **Long:** up to 20 m/s on long straights, but weak from standstill, and driving that fast drains the battery.

It costs no credits: the trade-off is all physics.

### Fixed for every car

Chassis 70 kg · wheelbase 1 m · steering up to 0.5 rad, at most 1.5 rad/s · drivetrain efficiency 0.85 · no energy
recovered when braking. **Mass = 70 kg + motor + battery + aero.** The starting car (`3.5kW`, `70Wh`, `medium`,
`lowdrag`, `medium`) costs 60 credits and weighs 91 kg.

---

## 🛣️ The paths

| Path | What it is | What it tests most |
|---|---|---|
| **Drag strip** (`"drag"`) | 150 m straight from a standing start, then **stop** inside a 10 m box | motor, gearing, mass, braking |
| **Technical circuit** (`"technical"`) | ≈ 370 m, hairpins, a chicane, short straights; 1 lap | tyres, mass, your controller |
| **Endurance** (`"endurance"`) | ≈ 380 m fast circuit with a hill; 5 laps | battery, aero, rolling loss, energy strategy |
| Wet practice (`"wet"`) | a short loop with one wet patch (grip × 0.6–0.8, flagged in advance); practice only | reading the road ahead |

**Race day** uses the same three kinds of path with **new layouts**: different straight lengths, corner radii and turn
directions. A car and controller tuned to the practice layouts will be caught out. Finishing rules and penalties are in
the *Reference* section below.

## 🏁 How you're scored

- Per path: **s = min(120, 100 × T_ref / T)**, where T is your time plus penalties and T_ref is the reference car's time.
  A DNF scores 0.
- **Overall = 0.6 × mean(s) + 0.4 × min(s).** Your **weakest path** counts for 40 %. A specialist scoring 95 / 95 / 20
  gets 50; an all-rounder scoring 75 / 75 / 75 gets 75.
- Ranking: cars that finished every path come first, ordered by overall score; then the others, by paths completed.
- Awards: 🏁 overall champion · ⚡ best single path · 🧠 best engineering explanation · 🤖 best use of the agent (the last
  two are judged from your `engineering_log.md`).

---

## ⚖️ Find your sweet spot: it's your call

No car is best on every path, for three reasons:

1. **Budget.** You have 80 credits, and the best of everything costs 105. Every credit spent on one part is a credit you
   can't spend on another.
2. **Mass.** Every motor, battery and aero upgrade adds kilograms, and every kilogram slows each acceleration (eq. 1)
   and costs energy up the hill (eq. 9). Without downforce, mass doesn't change the safe corner speed (m cancels in
   eq. 6), but it still slows you everywhere else.
3. **Physics.** Every ▲ above comes with a ▼. Grip costs rolling loss, downforce costs drag, pull costs top speed, and
   power and range cost mass.

The scoring makes this sharper. Suppose a change makes your best path 10 points better and your weakest path 5 points
worse. Your overall **drops**: 0.6 × (10 − 5) / 3 − 0.4 × 5 = −1. Before you keep any change, check **all three paths**.

The parts also **interact**. Whether 70 Wh is enough depends on your motor, gearing, aero and tyres, and on how hard your
controller drives. A part that's right for one car can be wrong for another.

And the car is only half of it. The Garage estimates assume a near-perfect driver. The starting controller drives at one
slow speed everywhere, so it uses only a fraction of what any car can do. **A better car only pays off if your controller
drives close to its limits.**

**How to search:**
1. Run `practiceRace('Path', 'all')` and find your **weakest path**.
2. Decide what you would give up to improve it. **Predict** which path pays for it, and write that in your log.
3. Try designs without touching your file: `d = carDesign(); d.tyres = "soft"; garage(d)`. (Run `garage` once first
   in each MATLAB session, so MATLAB can find your files.)
4. Compare all three paths every time. Keep the change only if the **overall** goes up.

There's no answer key. Two teams can race different cars and both be right, as long as each can show why.

---

## Who does what

| You: the race engineer | The agent: your pit crew |
|---|---|
| Decide which path to work on, and why | Runs MATLAB: `garage`, `practiceRace`, `plotLap` |
| Choose the designs to compare, and **predict** the result first | Gets the numbers and checks your prediction against the equations |
| **Choose** the parts and the driving strategy | Lays out the options, pros and cons, when you ask |
| Approve, change or reject every change; keep it or undo it | Makes **one** change, runs it, reports the numbers |
| Write your trade-off explanation in your own words | Checks it against the data, but doesn't write it for you |
| Keep `student/engineering_log.md` | Fills in measured numbers in the log when you ask |

The agent is set up to ask you before it decides anything (its rules are in `AGENTS.md`). If it decides for you anyway,
see **Taking back control** below.

---

## 🧭 Your steps

Everything you decide goes in **`student/engineering_log.md`**. It's handed in with your car, and the judges read it for
🧠 *best engineering explanation* and 🤖 *best use of the agent*.

| Step | Time | You do, or type to the agent | You decide (write it in the log) |
|---|---|---|---|
| **1. Meet your car** | 5 min | Yourself, in MATLAB: `cd(fullfile(getenv('USERPROFILE'), 'Documents', 'AI_Grand_Prix-main', 'AI_Grand_Prix'))`, then `garage`, then `practiceRace` (watch it drive), then `practiceRace('Path', 'all')` | Your baseline scores, your **weakest path**, and your guess *why* |
| **2. Brief the agent** | 3 min | `Read AGENTS.md and the project, then tell me in 5 bullet points what you understood. Don't change anything.` | Is its summary right? Correct it if not |
| **3. Design the car** | 10 min | Read *Find your sweet spot*. Write 1–2 candidate designs and your **prediction** in the log. Then: `Run the car-design-review skill on the candidates in my engineering log.` | The design you race, and your **trade-off** in your own words (3–4 sentences, with numbers). Then edit `student/carDesign.m` yourself (it's 5 lines) |
| **4. Choose how to drive** | 5 min | `Propose three ways my controller could choose its target speed from obs.previewPoints and obs.car. Pros, cons, and the risk on new layouts. Don't implement anything.` | Which approach, and why |
| **5. Improve, one change at a time** | 20 min, repeat | `Run the race-debrief skill on the technical path.` (or your weakest path) | What limits the car (say it *before* the agent does). Then approve, change or reject its one proposal, and after the run: keep it or undo it |
| **6. Check and submit** | 5 min | `Run Pattern 7 from AGENT_GUIDE.md.` (the overfitting check), then `submitCar` | Is it ready for layouts you have never seen? |

Steps 5–6 come back in the **final sprint** before the code freeze. You can go back to step 3 at any time: once your
controller drives better, a different car may be the better choice. More prompts, and how to write your own:
[AGENT_GUIDE.md](AGENT_GUIDE.md).

### ✅ Check the agent's work
- It **ran the race** after every change, and the numbers come from that run, not from "this should be faster".
- It changed **one** thing, only in `student/`, and only after you said yes.
- It named the **equation** behind each claim, and the explanation makes sense to you.
- Nothing in `controller.m` uses practice-track coordinates, corner positions or lap distances.
- You can explain every row of your change log **without looking at the agent's replies**.

### 🛑 Taking back control

| If the agent… | Type |
|---|---|
| decided something for you | `Stop. Undo that and give me the options instead. I'll choose.` |
| changed several things at once | `Undo all of that. Make only the first change, run it, and show me the numbers.` |
| wrote a long reply you can't follow | `In 3 bullet points: what you ran, what the numbers say, what you suggest.` |
| claims something without running it | `Run it and show me the numbers.` |
| wrote your explanation or prediction | `Delete that. I'll write it, and you check it.` |

---

# Reference

## Finishing, penalties, DNF

| | Finish | Penalties (still a finish) | DNF |
|---|---|---|---|
| Drag strip | cross the line, then **come to rest** | stop past the box (in the run-off): **+3 s** | hit the barrier at the end; over 30 s |
| Circuits | pass **every checkpoint in order**, cross the line forwards, every lap | off-track **+5 s** per incident; barrier **+10 s** per contact | a checkpoint missed (shortcut); stopped > 3 s; time limit; controller error |

An empty battery gives no drive: the car **coasts**, and still finishes if it rolls over the line.

---

## 🚀 Commands

```matlab
testMCP                                    % check that everything is installed
garage                                     % your car: drawing, numbers, cost, estimates
d = carDesign(); d.aero = "none"; garage(d)   % try a design without editing your file
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
├── student/                 ⭐ your files (all handed in by submitCar)
│   ├── engineering_log.md   your predictions, decisions and trade-off
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

*Predict → Test → Read the data → Decide → Race.*
