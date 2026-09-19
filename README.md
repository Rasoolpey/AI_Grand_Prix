# 🏎️ AI Grand Prix — Prompt. Build. Race.
### Agentic AI for Electrical Engineering with MATLAB

> **Build the fastest autonomous robot car using an AI engineering agent and MATLAB.**

This is a two-hour hands-on engineering competition where you work with an AI coding agent to develop, test, improve, and race a virtual autonomous car on a simulated race track.

---

## 🎯 Your Mission

You receive a working MATLAB simulator and a baseline controller that drives the car safely — but *slowly*. Your job is to use an AI agent to:

1. **Understand** the project and the controller interface
2. **Propose** control strategies
3. **Implement** a better autonomous controller
4. **Test** it on the practice track
5. **Diagnose** failures and improve
6. **Race** on a mystery track you haven't seen before

> The final race uses a **mystery track**. A solution hard-coded for the practice track will fail. Build something that generalises.

---

## 📂 Project Structure

```
AI_Grand_Prix/
├── README.md               ← You are here
├── SETUP.md                ← Start here BEFORE the workshop
├── AGENT_GUIDE.md          ← How to talk to your AI agent effectively
│
├── practiceRace.m          ← Run a local practice race
├── plotLap.m               ← Diagnostic plots for your agent to analyse
├── testMCP.m               ← Verify your agent↔MATLAB connection works
│
├── student/
│   ├── controller.m        ← ⭐ YOUR MAIN FILE — edit this with the agent
│   └── robotConfig.m       ← Optional: tuning hyperparameters
│
├── simulator/              ← DO NOT MODIFY
│   ├── Vehicle.m
│   ├── Track.m
│   ├── RaceSimulation.m
│   └── Visualizer.m
│
├── tracks/
│   └── practiceTrack.mat   ← Practice track (mystery track revealed at end)
│
└── mcp/
    ├── README.md            ← What MCP is and why you need it
    ├── claude_desktop_config.json
    ├── cursor_mcp.json
    └── test_mcp.m
```

---

## 🚀 Getting Started

### Step 1 — Set up your environment (before the workshop)
Follow the complete setup guide: **[SETUP.md](SETUP.md)**

This covers MATLAB, the MATLAB MCP server, and Claude Desktop configuration.

### Step 2 — Learn to prompt effectively
Read **[AGENT_GUIDE.md](AGENT_GUIDE.md)** for the prompt cheat-sheet.

### Step 3 — Verify your connection
Run `testMCP` in MATLAB, or ask your agent to run it for you.

### Step 4 — Start your first race
```matlab
% With visualisation (watch the car drive):
practiceRace

% Headless (faster — use this when iterating quickly):
practiceRace('Headless', true)

% Save results and diagnose:
r = practiceRace('Headless', true);
plotLap(r)
```

### Step 5 — Read the diagnostics
`plotLap` generates 4 panels your agent should analyse:
- **Trajectory** — is the car staying on track? cutting corners?
- **Speed profile** — where is it fast/slow relative to the track?
- **Steering angle** — is it oscillating? saturating at ±0.5 rad?
- **Cross-track error** — how far is it from the centreline?

### Step 6 — Build something great
Open `student/controller.m` and start working with your agent.
Read [AGENT_GUIDE.md](AGENT_GUIDE.md) for prompt templates that get results.

---

## 🏁 Scoring

| Metric | Points |
|---|---|
| Lap time | +1 per second |
| Off-track exit | +5 per event |
| Collision / barrier | +10 per event |
| Did Not Finish | DNF |

**Lowest score wins.** The official championship uses the mystery track under identical physics on the instructor's machine.

---

## 📋 Controller Interface

Your agent should modify `student/controller.m`. It receives:

```matlab
function command = controller(obs, config)
```

**Inputs (`obs`):**

| Field | Description |
|---|---|
| `obs.position` | `[x, y]` — vehicle position (m) |
| `obs.heading` | θ — heading angle (rad) |
| `obs.speed` | v — current speed (m/s) |
| `obs.previewPoints` | N×2 array of upcoming centreline points |
| `obs.trackWidth` | track width (m) |
| `obs.dt` | simulation timestep (s) |

**Outputs (`command`):**

| Field | Range | Description |
|---|---|---|
| `command.throttle` | −1 to +1 | negative = brake, positive = accelerate |
| `command.steering` | −1 to +1 | negative = left, positive = right |

The simulator enforces physical limits — you cannot exceed max speed, acceleration, or steering angle by commanding extreme values.

---

## 🤝 Rules

- Only modify files in the `student/` folder
- Do **not** modify anything in `simulator/`
- Your controller must work on an **unseen track** — no hard-coding track coordinates
- Your AI agent is a tool — **you** are the engineer responsible for the result

---

## 📞 Need Help?

1. Ask your AI agent — that's the point!
2. Check [AGENT_GUIDE.md](AGENT_GUIDE.md) for prompt examples
3. Run `plotLap` to get diagnostic plots your agent can analyse
4. Flag a tutor if you're completely stuck

---

*Good luck. Prompt → Build → Test → Fail → Diagnose → Improve → Race.*
