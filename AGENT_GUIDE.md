# 🧠 Agent Guide — How to Build a Race Car with AI

> *"The quality of your output is determined by the quality of your input."*

This guide teaches you how to talk to your AI engineering agent effectively. The difference between a student who gets a mediocre controller and one who wins the championship often isn't the algorithm — it's **how they communicate with their agent**.

---

## The Golden Rule

> **The agent must read before it writes.**

Before your agent touches any code, it should fully understand the project. An agent that edits code it hasn't read produces garbage.

**Use this as your very first prompt — every session:**

```
Read and understand the entire project before making any changes.
Specifically:
- Read README.md to understand the competition
- Read student/controller.m to understand the interface
- Inspect the obs struct fields and what each means
- Read simulator/Vehicle.m to understand physical constraints
- Confirm which files you are and are not allowed to modify

Do not write any code yet. Report back what you found.
```

---

## The Agentic Engineering Loop

Every improvement should follow this cycle:

```
1. SPECIFY  — Tell the agent exactly what you want to achieve
      ↓
2. INSPECT  — Agent reads the relevant code/results
      ↓
3. IMPLEMENT — Agent makes a targeted, specific change
      ↓
4. RUN      — Agent runs practiceRace or plotLap
      ↓
5. OBSERVE  — You (and the agent) read the output
      ↓
6. DIAGNOSE — What went wrong? What improved?
      ↓
7. IMPROVE  — Return to step 1 with better information
```

Never skip step 5. Never assume it worked without running the simulation.

---

## Prompt Pattern Library

These are copy-paste prompts for common situations. Adapt them — don't just copy them blindly.

---

### 📖 Pattern 1 — Understand the project

Use this at the **start of every session**.

```
Read the entire project before doing anything.

1. Read README.md — understand the competition rules and scoring
2. Read student/controller.m — understand the controller interface in detail
3. Read simulator/RaceSimulation.m — understand how the simulation calls the controller
4. Read simulator/Vehicle.m — identify all physical constraints I cannot exceed

After reading, summarise:
- What inputs does my controller receive?
- What outputs must it produce?
- What physical limits exist that I cannot change?
- Which files am I allowed to modify?
```

---

### 🔍 Pattern 2 — Investigate approaches before implementing

Use this when you don't yet know which algorithm to use.

```
I need an autonomous controller for a virtual race car.
The controller receives: position, heading, speed, upcoming centreline points, 
track width, and timestep.

Propose THREE different steering control strategies suitable for this project.
For each one:
- Name it
- Explain how it works in simple terms
- List its advantages for this racing scenario
- List its disadvantages or risks
- Rate its implementation complexity (simple / medium / complex)

Do not implement anything yet. I will choose which approach to try.
```

---

### 🚗 Pattern 3 — First implementation (conservative)

Use this once you've chosen an approach.

```
Implement a [CHOSEN APPROACH] in student/controller.m.

Requirements:
- Use only the fields available in the obs struct (see comments in controller.m)
- Do not modify anything in the simulator/ folder
- Start conservative: prioritise track completion over speed
- Add clear comments explaining each calculation
- Keep the implementation in a single function for now

After implementing, run practiceRace and report:
- Did the car complete a lap?
- What was the lap time?
- Were there any track exits?
```

---

### 🔬 Pattern 4 — Diagnose a failure

Use this when the car crashes, leaves the track, or behaves strangely.

```
The car is leaving the track on sharp corners.

1. Run practiceRace in headless mode to get simulation data
2. Run plotLap to generate diagnostic plots
3. Look at the steering angle vs. curvature plot — is steering saturating?
4. Look at the speed profile — is the car entering corners too fast?
5. Check whether the preview points correctly predict the upcoming corner

Based on the data (not guessing), identify the root cause and propose 
one targeted fix. Explain WHY this fix should help before implementing it.
```

---

### ⚡ Pattern 5 — Improve speed (after the car safely completes laps)

Use this only once your car reliably completes laps without going off-track.

```
The car completes the track but is slow. Current lap time: [X seconds].

I want to improve speed on straights without sacrificing corner stability.

1. Run practiceRace and examine the speed profile
2. Identify sections where the car is travelling well below the speed limit
3. Propose a specific speed control improvement using upcoming curvature from 
   previewPoints to detect when we are on a straight vs. approaching a corner
4. Implement the change and run practiceRace again
5. Compare lap times and report whether any new track exits occurred

Do not just increase maxSpeed. Think about WHERE to be fast vs. WHERE to brake.
```

---

### 🌍 Pattern 6 — Check for overfitting (important!)

Use this before the final submission. The mystery track will catch overfitted solutions.

```
Review student/controller.m critically.

Check for any code that:
- Uses specific coordinates from the practice track
- Has constants that only work for particular corners or straight lengths
- Makes assumptions about the overall track shape or orientation
- Hard-codes any turn directions or distances

For each suspicious item, explain whether it is a track-specific hack or a 
general engineering decision.

Then propose changes to make the controller more general. The final race uses 
a completely different track — this controller must work on any track.
```

---

### 📊 Pattern 7 — Generate diagnostic analysis

Use this to give the agent data to work with rather than guessing.

```
Run practiceRace in headless mode, then run plotLap.

Analyse the resulting plots:
1. Trajectory vs centreline — is the car cutting corners? hugging the inside?
2. Speed profile — where is it fastest/slowest? Does it match the curvature?
3. Steering angle — is it smooth or oscillating? Does it saturate frequently?
4. Any correlation between high steering angle and track exits?

Based on this analysis, identify the single most impactful thing to fix next.
```

---

### ✅ Pattern 8 — Final validation

Use this in the last 10 minutes before code freeze.

```
Run practiceRace 3 times and record the results.

For each run:
- Lap time
- Number of track exits
- Computed score (lap time + 5 × exits)

Then review the controller for anything that might fail on an unseen track:
- Does it make any assumptions that won't generalise?
- Are there any edge cases that could cause a crash on a different layout?

Give me a summary: is this controller ready for the mystery track?
```

---

## Anti-Patterns — What NOT to Do

These are the most common mistakes. Avoid them.

---

### ❌ Vague requests

```
❌ "Make the car faster."
✅ "Increase speed on straight sections by estimating curvature from previewPoints 
    and targeting a speed inversely proportional to curvature. Keep exits at zero."
```

---

### ❌ Trusting output without running

```
❌ "The agent implemented it, so it must work."
✅ Always run practiceRace after any change. If the agent didn't run it, ask it to.
```

---

### ❌ "Fix it" without data

```
❌ "The car crashed. Fix it."
✅ "The car crashed on corner 3. Run plotLap and diagnose the speed entering that 
    corner. Show me the steering angle trace. Then propose a fix based on what 
    you see in the data."
```

---

### ❌ Too many changes at once

```
❌ "Rewrite the whole controller with a new algorithm and also add adaptive speed."
✅ Make one change. Run the race. See if it improved. Then make the next change.
```

---

### ❌ Ignoring the mystery track

```
❌ Optimising purely for the practice track layout.
✅ Regularly ask: "Will this work on a track with different corner radii and 
    directions?"
```

---

## Understanding What the Agent Can Do

Your AI agent has these **tools** available via MCP:

| Tool | What it does |
|---|---|
| Read file | Read any file in the project |
| Write file | Edit `student/controller.m` and `student/robotConfig.m` |
| Run MATLAB | Execute `practiceRace`, `plotLap`, `testMCP`, or any MATLAB command |
| Get output | Read MATLAB console output and return it to you |

The agent **cannot** (and should not):
- Modify files in `simulator/`
- Access the mystery track
- Change the vehicle physics
- Connect to external internet resources

---

## Tips for Getting the Best Results

1. **Be specific about constraints** — "don't exceed 2 track exits" is clearer than "don't go off track"
2. **Give the agent context** — paste the MATLAB output into the chat if it didn't run it itself
3. **Ask for reasoning** — "explain why this change should help before implementing it"
4. **Challenge the output** — "are there any situations where this would fail?"
5. **One thing at a time** — iterative small improvements beat one big rewrite
6. **Use the data** — `plotLap` exists so the agent can diagnose from real telemetry, not guessing

---

## A Good First 15-Minute Workflow

```
Minute 0-3:   Use Pattern 1 — understand the project
Minute 3-6:   Use Pattern 2 — investigate approaches
Minute 6-10:  Choose one approach, use Pattern 3 — implement it conservatively
Minute 10-13: Run practiceRace — does it complete a lap?
Minute 13-15: If yes → Pattern 5 (speed). If no → Pattern 4 (diagnose).
```

---

*Remember: the agent is your engineering assistant. You are the engineer. The agent accelerates your loop — it doesn't remove your responsibility to think.*
