# AI Grand Prix Workshop — TODO

Based on [AI_Grand_Prix_Workshop_Plan.md](file:///c:/Users/em18736/Documents/MatlabWorkshop/AI_Grand_Prix_Workshop_Plan.md)

---

## 🧰 Phase 1 — Single-Car Local Simulator
> Goal: `practiceRace` runs a car around one track.

- [ ] Design and implement 2D kinematic vehicle model (`Vehicle.m`)
  - [ ] State: x, y, θ, v
  - [ ] Inputs: throttle (a), steering (δ)
  - [ ] Enforce immutable vehicle physical constraints (max speed, acceleration, braking, steering angle/rate)
  - [ ] Optional: lateral acceleration constraint ($a_{lat} = v^2 |\kappa|$)
- [ ] Build `Track.m` — track representation
  - [ ] Centre-line points
  - [ ] Track width
  - [ ] Start/finish line
  - [ ] Optional: left/right boundaries
  - [ ] Optional: curvature pre-computation
- [ ] Build `RaceSimulation.m`
  - [ ] Numerical integration loop with fixed timestep $\Delta t = 0.02\text{ s}$
  - [ ] Call `controller(obs, config)` at each step
  - [ ] Construct `obs` struct (`position`, `heading`, `speed`, `previewPoints`, `trackWidth`, `dt`)
- [ ] Build `Visualizer.m` — live 2D animation of vehicle on track
- [ ] Create `practiceRace.m` — top-level local runner script
  - [ ] Interactive animated mode (for human visual observation)
  - [ ] Fast / headless simulation flag (e.g. `practiceRace('Headless', true)`) for rapid AI agent iterations (< 0.5 s per lap)
- [ ] Build diagnostic plotting utility (`plotLap.m`)
  - [ ] Trajectory vs. centerline plot
  - [ ] Speed and throttle profile vs. track distance
  - [ ] Steering angle vs. curvature profile
  - [ ] Visual telemetry feedback for both students and the AI agent to diagnose failures
- [ ] Create practice track file (`tracks/practiceTrack.mat`)
  - [ ] Include straight sections
  - [ ] Include mild turns
  - [ ] Include at least one sharp turn
  - [ ] Include corners in both directions

---

## 🤖 Phase 2 — Baseline Controller
> Goal: A conservative controller that already completes the practice track slowly.

- [ ] Implement baseline `controller.m` using simple Pure Pursuit
  - [ ] Low fixed speed
  - [ ] Conservative look-ahead distance
- [ ] Verify the baseline completes the practice track without leaving it
- [ ] Create `student/robotConfig.m` with controller tuning hyperparameters
  - [ ] Clarify scope: controller hyperparameters only (e.g. `lookaheadDistance`, `targetSpeed`, `kp`), NOT physical limits
  - [ ] Verify `Vehicle.m` overrides or clamps any attempts to exceed physical limits

---

## 🏁 Phase 3 — Scoring System
> Goal: Objective, visible, and fair scoring for students.

- [ ] Implement lap completion detection (crossing finish line in correct direction)
- [ ] Implement lap timing
- [ ] Implement debounced / edge-triggered off-track detection
  - [ ] Detect state transition (on-track → off-track) to avoid counting 50 violations per second
  - [ ] Apply hysteresis threshold before re-arming off-track counter
- [ ] Implement collision / barrier contact detection
- [ ] Implement penalty formula: $\text{Score} = T_{lap} + 5 \times N_{offtrack} + 10 \times N_{collision}$
- [ ] Implement DNF (Did Not Finish) logic (time limit exceeded, backwards driving, irrecoverable off-track)
- [ ] Display end-of-race summary in terminal (team name, lap time, exits, penalties, final score)

---

## 🗺️ Phase 4 — Mystery Track Validation
> Goal: Confirm good generic controllers work on unseen tracks while overfitted ones fail.

- [ ] Design at least one mystery track (different layout, same format and physics)
- [ ] Design an optional second mystery track for extra validation
- [ ] Test baseline controller on mystery track (should still complete safely)
- [ ] Test a tuned high-performance controller on mystery track
- [ ] Create a deliberately overfitted controller (hard-coded turns from practice track) to verify it fails on mystery track

---

## 📦 Phase 5 — Student Project Package
> Goal: A clean, self-contained project students receive on the day.

- [ ] Finalise project folder structure:
  ```text
  AI_Grand_Prix/
  ├── practiceRace.m         # Local runner (interactive or headless)
  ├── plotLap.m              # Visual diagnostics for agent & student
  ├── joinRace.m             # Connect to championship server (Phase 7)
  ├── testMCP.m              # Sanity check for agent-MATLAB connection
  ├── README.md              # Student instructions
  ├── student/
  │   ├── controller.m       ← MAIN FILE TO MODIFY
  │   └── robotConfig.m      # Hyperparameter tuning
  ├── simulator/             ← DO NOT MODIFY
  │   ├── Vehicle.m
  │   ├── Track.m
  │   ├── RaceSimulation.m
  │   └── Visualizer.m
  └── tracks/
      └── practiceTrack.mat
  ```
- [ ] Write `README.md` for students
  - [ ] Project overview & challenge mission
  - [ ] How to run `practiceRace` (normal and headless mode)
  - [ ] How to run `plotLap` for diagnostic graphs
  - [ ] Explanation of `obs` fields and `command` outputs
  - [ ] Example agent prompts (from §26 of the plan)
  - [ ] Scoring explanation & penalty rules
  - [ ] Code-freeze & submission instructions
- [ ] Create MCP configuration templates & setup guides
  - [ ] Provide sample config files for target environments (Claude Desktop, Cursor, Antigravity/Gemini, VS Code Roo Code)
  - [ ] Include `testMCP.m` script to verify tool-calling / execution works smoothly
- [ ] Write printed student instruction sheet (§25 wording)
- [ ] Create example prompt cheat-sheet (§26) for students
- [ ] Mark simulator folder as **DO NOT MODIFY** (comments + README warning)
- [ ] Write pre-workshop setup guide (MATLAB version, toolboxes, MCP setup, agent setup, firewall)

---

## 🖥️ Phase 6 — Central Evaluator (Offline Mode)
> Goal: Instructor can run all submitted controllers reliably under identical conditions.

- [ ] Establish submission format: `submissions/<team_name>/controller.m` (and optional `robotConfig.m`)
- [ ] Build `evaluateAll.m` championship runner script
  - [ ] Dynamically discover and load each team's controller without namespace collisions
  - [ ] Sandbox execution in `try/catch` blocks (crashed controller = DNF, not script crash)
  - [ ] Implement execution timeout guard per timestep / lap (prevent infinite loops from hanging the race)
  - [ ] Run each on the mystery track under identical physics, fixed $\Delta t$, and CPU environment
  - [ ] Collect lap times, penalties, and DNF statuses
  - [ ] Generate and display sorted final leaderboard table

---

## 🌐 Phase 7 — Network Race (Optional / Post-MVP)
> Goal: Live multiplayer race over lab LAN/Wi-Fi.

- [ ] Implement TCP race server (instructor PC)
  - [ ] Team registration & handshake
  - [ ] Send JSON observations to each team each timestep
  - [ ] Receive and apply controller JSON commands
  - [ ] Enforce controller-response timeout per step
  - [ ] Timing & scoring engine
  - [ ] Ghost-car model (cars pass through each other without collision)
- [ ] Implement `joinRace.m` — student TCP client
  - [ ] Hides all networking details from students
  - [ ] Calls `controller(obs, config)` and sends command
- [ ] Test on lab network
  - [ ] Confirm network latency does not affect simulated lap time (fixed dt model)
  - [ ] Test under Wi-Fi packet jitter / firewall settings
- [ ] Implement multi-car live visualisation (all teams on same projected display)
  - [ ] Live standings / leaderboard overlay

---

## 📊 Phase 8 — Instructor Dashboard (Optional)
> Goal: MATLAB App Designer race-control interface.

- [ ] Build App Designer application
  - [ ] Connected team list with status (Ready / Waiting)
  - [ ] Mode selector: Practice / Qualifying / Final
  - [ ] Track selector
  - [ ] Start Race / Stop Race buttons
  - [ ] Code-freeze indicator
  - [ ] Live track display
  - [ ] Live leaderboard
  - [ ] Export results button (CSV / summary report)

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
- [ ] `practiceRace` runs the baseline controller on the practice track without errors
- [ ] Headless simulation flag allows completing a simulated lap in < 0.5 s
- [ ] Diagnostic plotting utility (`plotLap.m`) works and provides interpretable telemetry for agents & students
- [ ] A student can open `controller.m`, edit it with an AI agent, and observe improvement
- [ ] Scoring and debounced off-track detection produce correct, fair results
- [ ] At least one mystery track is ready for central evaluation
- [ ] Central evaluator (`evaluateAll.m`) executes multiple submissions with `try/catch` and timeout protection
- [ ] Student README, setup guide, MCP config template, and instruction sheet are ready
- [ ] Tested successfully on a clean MATLAB install
