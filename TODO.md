# AI Grand Prix Workshop — TODO

Based on [AI_Grand_Prix_Workshop_Plan.md](file:///c:/Users/em18736/Documents/MatlabWorkshop/AI_Grand_Prix_Workshop_Plan.md)

---

## 🔧 Phase 0 — Agent Setup & Documentation
> Goal: Every student can reproduce the exact same agent+MATLAB environment by following the repo docs.
> ✅ **Complete** — committed and pushed to [github.com/Rasoolpey/AI_Grand_Prix](https://github.com/Rasoolpey/AI_Grand_Prix)

- [x] Create repo structure and initialise Git (`main` branch)
- [x] Add `.gitignore` (MATLAB temps, Python venvs, OS files)
- [x] Add `.gitattributes` (normalise line endings for Windows/Mac teams)
- [x] Write `README.md` — top-level intro, project structure, scoring table, controller interface quick-ref
- [x] Write `SETUP.md` — complete pre-workshop setup guide
  - [x] MATLAB version requirement (R2024a+)
  - [x] Python 3.11/3.12 install instructions
  - [x] MATLAB MCP server install (`github.com/matlab/matlab-mcp-server`)
  - [x] Claude Desktop install and `claude_desktop_config.json` configuration
  - [x] Troubleshooting section (firewall, PowerShell permissions, path errors)
  - [x] Alternative agents: Cursor, Antigravity/Gemini
  - [x] Pre-workshop checklist for students
- [x] Write `AGENT_GUIDE.md` — prompt engineering cheat-sheet
  - [x] The golden rule: agent reads before it writes
  - [x] The agentic engineering loop (Specify → Inspect → Implement → Run → Observe → Diagnose → Improve)
  - [x] 8 prompt patterns (understand, investigate, implement, diagnose, improve speed, check generalisation, diagnostic analysis, final validation)
  - [x] Anti-patterns section
- [x] Create `mcp/` folder
  - [x] `mcp/README.md` — plain-English MCP explainer
  - [x] `mcp/claude_desktop_config.json` — drop-in template (3 paths to fill in)
  - [x] `mcp/cursor_mcp.json` — alternative config for Cursor IDE
  - [x] `mcp/test_mcp.m` — sanity-check script
- [x] Create `student/controller.m` — baseline Pure Pursuit controller with full `obs` struct docs
- [x] Create `student/robotConfig.m` — tuning hyperparameters with clear documentation
- [x] Push Phase 0 to GitHub (`github.com/Rasoolpey/AI_Grand_Prix`)

---

## 🧰 Phase 1 — Single-Car Local Simulator
> Goal: `practiceRace` runs a car around one track.

- [x] Design and implement 2D kinematic vehicle model (`Vehicle.m`)
  - [x] State: x, y, θ, v
  - [x] Inputs: throttle (a), steering (δ)
  - [x] Enforce immutable vehicle physical constraints (max speed, acceleration, braking, steering angle/rate)
- [x] Build `Track.m` — track representation
  - [x] Centreline points
  - [x] Track width
  - [x] Start/finish line
  - [x] Left/right boundaries
  - [x] Nearest-point and cross-track error queries
- [x] Build `RaceSimulation.m`
  - [x] Numerical integration loop with fixed timestep Δt = 0.02 s
  - [x] Call `controller(obs, config)` each step
  - [x] Construct full `obs` struct (position, heading, speed, previewPoints, trackWidth, dt)
- [x] Build `Visualizer.m` — live 2D animation (dark theme, position trail, HUD)
- [x] Create `practiceRace.m` — top-level runner
  - [x] Interactive animated mode
  - [x] Headless flag: `practiceRace('Headless', true)` for rapid iteration
- [x] Build `plotLap.m` — 4-panel diagnostic figure
  - [x] Trajectory vs centreline (coloured by speed)
  - [x] Speed profile vs track distance
  - [x] Steering angle vs track distance (with saturation lines)
  - [x] Cross-track error vs track distance
- [x] Create practice track (`tracks/createPracticeTrack.m` + auto-save to mat)
  - [x] Long start straight
  - [x] Mild right-hand sweep
  - [x] Tight 180° hairpin
  - [x] Left-hand return section
  - [x] Second closing hairpin (both directions represented)

---

## 🤖 Phase 2 — Baseline Controller
> Goal: A conservative controller that already completes the practice track slowly.

- [x] Implement baseline `controller.m` using Pure Pursuit
  - [x] Conservative look-ahead distance
  - [x] Safe defaults via `robotConfig()`
  - [x] No Signal Processing Toolbox dependency (custom `wrapAngle` helper)
- [ ] Verify baseline completes practice track without leaving it — *pending first MATLAB run*
- [x] Create `student/robotConfig.m` as a function returning tuning hyperparameters
  - [x] lookaheadDistance, targetSpeed, steeringGain, throttleGain
  - [x] Example comments for student-defined parameters
  - [x] Vehicle physical limits enforced by simulator (cannot be overridden)

---

## 🏁 Phase 3 — Scoring System
> Goal: Objective, visible, and fair scoring for students.

- [x] Implement lap completion detection (S/F line segment crossing)
- [x] Implement lap timing
- [x] Implement debounced off-track detection (on→off state transition, not per-frame)
- [x] Implement collision detection (crossErr > trackWidth)
- [x] Implement penalty formula: Score = LapTime + 5×exits + 10×collisions
- [x] Implement DNF logic (timeout, excessive exits, irrecoverable off-track)
- [x] Display end-of-race summary in terminal

---

## 🗺️ Phase 4 — Mystery Track Validation
> Goal: Confirm good generic controllers work on unseen tracks while overfitted ones fail.

- [x] Design mystery track (`tracks/createMysteryTrack.m`) — different layout, same format
  - [x] 8 segments: tight right corners, sweeping left, closing hairpin
  - [x] Excluded from repo via .gitignore (instructor-only)
- [ ] Test baseline controller on mystery track — *pending MATLAB run*
- [ ] Deliberately overfitted controller validation — *workshop day activity*

---

## 📦 Phase 5 — Student Project Package
> Goal: A clean, self-contained project students receive on the day.

- [/] Finalise project folder structure: *(Phase 0 scaffold done; simulator files pending Phase 1)*
  ```text
  AI_Grand_Prix/
  ├── practiceRace.m         # [ ] Phase 1
  ├── plotLap.m              # [ ] Phase 1
  ├── joinRace.m             # [ ] Phase 7
  ├── README.md              # [x] Done
  ├── SETUP.md               # [x] Done
  ├── AGENT_GUIDE.md         # [x] Done
  ├── student/
  │   ├── controller.m       # [x] Done (baseline Pure Pursuit + full obs docs)
  │   └── robotConfig.m      # [x] Done
  ├── mcp/                   # [x] Done
  │   ├── README.md
  │   ├── claude_desktop_config.json
  │   ├── cursor_mcp.json
  │   └── test_mcp.m
  ├── simulator/             # [ ] Phase 1 — DO NOT MODIFY
  │   ├── Vehicle.m
  │   ├── Track.m
  │   ├── RaceSimulation.m
  │   └── Visualizer.m
  └── tracks/
      └── practiceTrack.mat  # [ ] Phase 1
  ```
- [x] Write `README.md` for students
  - [x] Project overview & challenge mission
  - [ ] How to run `practiceRace` (normal and headless mode) — *needs Phase 1*
  - [ ] How to run `plotLap` for diagnostic graphs — *needs Phase 1*
  - [x] Explanation of `obs` fields and `command` outputs
  - [x] Example agent prompts (from §26 of the plan) — *see AGENT_GUIDE.md*
  - [x] Scoring explanation & penalty rules
  - [ ] Code-freeze & submission instructions
- [x] Create MCP configuration templates & setup guides
  - [x] Provide sample config files for target environments (Claude Desktop, Cursor, Antigravity/Gemini, VS Code Roo Code)
  - [x] Include `testMCP.m` script to verify tool-calling / execution works smoothly
- [ ] Write printed student instruction sheet (§25 wording)
- [x] Create example prompt cheat-sheet (§26) for students — *see AGENT_GUIDE.md*
- [ ] Mark simulator folder as **DO NOT MODIFY** (comments + README warning) — *Phase 1*
- [x] Write pre-workshop setup guide (MATLAB version, toolboxes, MCP setup, agent setup, firewall) — *see SETUP.md*

---

## 🖥️ Phase 6 — Central Evaluator (Offline Mode)
> Goal: Instructor can run all submitted controllers reliably under identical conditions.

- [x] Establish submission format: `submissions/<team_name>/controller.m` + optional `robotConfig.m`
- [x] Build `evaluateAll.m` championship runner script
  - [x] Discover team folders automatically
  - [x] Path-isolated controller loading (each team's controller.m separate)
  - [x] `try/catch` sandbox (crashed controller = DNF, not script crash)
  - [x] `clear controller` + `rehash()` between teams to avoid caching collisions
  - [x] Run on any track under identical physics and fixed Δt
  - [x] Collect lap times, penalties, and DNF statuses
  - [x] Sorted final leaderboard with positions
- [x] Create `submissions/README.md` with submission instructions and scoring reminder

---

## 🌐 Phase 7 — Network Race (Optional / Post-MVP)
> Goal: Live multiplayer race over lab LAN/Wi-Fi.

- [x] Create `joinRace.m` stub — documents interface, ready for TCP expansion
  - [x] Correct `obs`/`command` interface (identical to practiceRace)
  - [x] Commented TCP skeleton using `tcpclient` + JSON encode/decode
- [ ] Implement TCP race server (instructor PC) — *post-workshop expansion*
- [ ] Test on lab network — *post-workshop expansion*
- [ ] Multi-car live visualisation — *post-workshop expansion*

---

## 📊 Phase 8 — Instructor Dashboard (Optional)
> Goal: MATLAB App Designer race-control interface. *Deferred — post-MVP.*

- [ ] Build App Designer application (deferred — not required for workshop MVP)
  - [ ] Connected team list with status
  - [ ] Track selector and race mode (Practice / Qualifying / Final)
  - [ ] Start / Stop buttons
  - [ ] Live track display with all car positions
  - [ ] Live leaderboard
  - [ ] Export results (CSV / report)

---

## 🎓 Workshop Delivery Preparation
> Goal: Ready to run the 2-hour workshop seamlessly.

### Instructor Setup
- [ ] MATLAB installed and tested
- [ ] Required MathWorks toolboxes installed (Robotics, Navigation, etc.)
- [ ] MATLAB MCP server installed and configured
- [ ] AI agent tested with MCP + MATLAB (verify prompt-to-run loop)
- [ ] Race project tested end-to-end
- [ ] Network connectivity tested (if using Phase 7)
- [ ] Projector / display tested

### Race Infrastructure
- [ ] Practice track ready
- [ ] Mystery track(s) ready and kept secret
- [ ] Baseline controller verified
- [ ] Scoring and penalty rules finalised and tested
- [ ] DNF rules documented
- [ ] Submission method established (shared network drive / USB drop / email / LMS drop-box)
- [ ] Practice leaderboard method prepared for minute 75–90 qualifying sprint
- [ ] Backup offline evaluation pipeline verified (`evaluateAll.m`)

### Workshop Slides & Handouts
- [ ] Introduction slides (§24: what is an AI agent, what is MCP, agentic loop diagram)
- [ ] Competition brief slides (robot model, obs fields, scoring, rules, mystery track warning)
- [ ] Live demonstration script prepared (§24: 10–20 min demo showing prompt → edit → fail → diagnose → improve)
- [ ] Tutor briefing notes (how to guide prompt engineering and debugging without giving away control algorithms)
- [ ] Slide on Safety & Responsible Agent Use in Physical Systems (§34: human-in-the-loop, verification before physical deployment)
- [ ] (Optional) Prep ABB YuMi physical robot demonstration (§33)

### Awards
- [ ] 🏁 Fastest Robot prize
- [ ] 🧠 Best Engineering Solution prize
- [ ] 🤖 Best Use of AI Agent prize
- [ ] 💡 Most Creative Solution prize (optional)
- [ ] Certificates / prizes procured

---

## ✅ Definition of Done (MVP)
The workshop is ready when:
- [x] `practiceRace` code exists and is ready to run
- [x] Headless mode flag implemented for fast agent iteration
- [x] `plotLap.m` generates 4-panel diagnostic figure
- [x] Student can open `controller.m`, understand the interface, and edit with an AI agent
- [x] Scoring and debounced off-track detection built into `RaceSimulation.m`
- [x] Mystery track generator ready (`createMysteryTrack.m`)
- [x] `evaluateAll.m` runs all submissions with try/catch and leaderboard output
- [x] Student README, `SETUP.md`, `AGENT_GUIDE.md`, MCP configs ready
- [x] `simulator/README.md` has clear DO NOT MODIFY notice
- [x] All code committed and pushed to GitHub
- [ ] Tested end-to-end on a clean MATLAB install — *pre-workshop task*
