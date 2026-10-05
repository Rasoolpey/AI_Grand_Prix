# 🧠 Agent Guide: how to run your pit crew

> *"The quality of your output is determined by the quality of your input."*

Your agent can read the whole project, run MATLAB and rewrite your controller in seconds. That speed is only useful if
**you** stay the engineer: you set the goal, you predict, you read the result, you decide. The team that wins usually
isn't the one with the cleverest algorithm. It's the one that runs the most **good** loops, each one with a clear
question and a decision at the end.

The steps for the session are in [README.md](README.md) ("Your steps"). This guide is about **how to talk to the agent**.

---

## Two golden rules

1. **You decide, the agent does the legwork.** Ask it for evidence and options, not for answers. If you couldn't explain
   a change to the judges, don't keep it.
2. **The agent reads before it writes.** An agent that edits code it hasn't read produces garbage. Start every session
   with Pattern 1.

---

## The loop: who does what

```
1. SPECIFY   you     what to improve, on which path, and what must not get worse
2. PREDICT   you     what you expect to happen, and why (which equation)
3. INSPECT   agent   reads the code, runs the race, reads the telemetry
4. PROPOSE   agent   options, or ONE change, with the reason and the risk
5. DECIDE    you     approve it, change it, or reject it
6. RUN       agent   makes that one change and runs practiceRace
7. COMPARE   you     was your prediction right? keep or undo? one row in engineering_log.md
```

Never skip 2 and 7: they're where you learn something. Never assume a change worked without running it.

---

## How to write a good prompt

Five parts. Most bad prompts are missing the last three.

```
GOAL:       what to improve, on which path
KEEP:       what must not get worse (no penalties, energy must last, ...)
I THINK:    my guess and why (name the equation)
SHOW ME:    the numbers or options I need to decide
THEN WAIT:  don't change anything until I say yes
```

Example:

```
Goal: faster on the technical circuit.
Keep: no penalties on any path.
I think: the car brakes far too early for the hairpins, because it drives at one
target speed everywhere instead of the eq. 6 corner speed.
Show me: the speed vs eq. 6 panel for that lap, and where the car is furthest below the line.
Then wait: propose one change, but don't make it until I say yes.
```

---

## Prompt patterns

Copy them, but fill in the brackets with **your** thinking. The brackets are the point.

### 📖 Pattern 1: Brief the agent (step 2, and the start of every session)

```
Read AGENTS.md, README.md, PHYSICS.md, everything in student/ (including
engineering_log.md), and run garage.

Then tell me, in 5 bullet points:
- what the three paths test and how they're scored
- what my controller receives and what it must return
- which files you may and may not change
- what I have decided so far (from my log)

Don't change anything.
```

**You decide:** is the summary right? If it got something wrong, correct it now, before it writes any code.

---

### 🏎️ Pattern 2: Compare car designs (step 3)

Fill in section 2 of your log first. Then:

```
My weakest path is [path], because [reason, equation].
Candidate B: [change], I expect [better] on [path] and [worse] on [path].
Candidate C: [change], I expect [better] on [path] and [worse] on [path].

Run the car-design-review skill on these. Tell me where my predictions were wrong
and which equation explains it. Don't recommend one yet.
```

**You decide:** which design you race, and your trade-off, written in your own words in the log. Then ask:
`Check my trade-off in the log against the numbers. Don't rewrite it, just tell me what's wrong or missing.`

---

### 🔍 Pattern 3: Investigate approaches before implementing (step 4)

```
My controller must choose a steering command and a target speed from
obs.previewPoints, obs.speed and obs.car (see README.md).

Propose THREE different approaches for [steering / the target speed].
For each one:
- how it works, in 2-3 sentences
- why it would or wouldn't suit these paths
- what could go wrong on a layout it has never seen
- implementation complexity (simple / medium / complex)

Don't implement anything. I'll choose.
```

**You decide:** which approach, and why. Write it in section 3 of the log.

---

### 🚗 Pattern 4: First implementation (conservative)

```
Implement [the approach I chose] in student/controller.m, because [my reason].

- Use only the fields in obs (see the comments in controller.m)
- Start conservative: finishing every path matters more than speed
- Comment each calculation
- Put any tuning values in robotConfig.m

I expect it to [my prediction: faster/slower on which path, any penalties?].
Then run practiceRace('Path', 'all') and show me time, penalties, energy and
score for each path, and the overall score.
```

**You decide:** was your prediction right? Keep it, or undo it?

---

### 🔬 Pattern 5: Diagnose a problem

```
Run the race-debrief skill on the [path] path.
```

The skill asks you first what you think limits the car. **Answer it.** Look at `lapPlot.png` and name the panel that
shows the problem. If you're really stuck, say "just tell me", but try first: it's the most useful minute of the loop.

For a specific failure, add your observation:

```
The car leaves the track at [where]. I think [why: too fast for eq. 6? braking
while turning (eq. 5)? the preview doesn't see the corner?]. Run the race-debrief
skill on [path] and tell me whether the data agree with me.
```

**You decide:** approve, change or reject the one proposed change. After the run, keep it or undo it. Write one row in
the change log.

---

### ⚡ Pattern 6: Improve speed (once every path finishes cleanly)

```
Every path finishes. Current times: [drag, technical, endurance].
Goal: faster on [path]. Keep: no new penalties on any path.

I think the car is slowest where [section], because [reason].

Show me where the car is furthest below the eq. 6 limit and the benchmark.
Then propose ONE change. Don't make it until I say yes.
```

Don't just raise `targetSpeed`. Think about **where** to be fast and **where** to brake (PHYSICS.md, "How to use
equation 6").

---

### 🌍 Pattern 7: Check for overfitting (step 6, before every submission)

The final paths are new layouts. They will catch overfitted controllers.

```
Review student/controller.m and student/robotConfig.m critically.

List anything that:
- uses coordinates from a practice path
- only works for particular corners, straight lengths or lap distances
- assumes a track shape, orientation or turn direction
- depends on path-specific timings

For each item, say whether it's a track-specific hack or a general engineering
decision, and why. Don't change anything.
```

**You decide:** which items to fix. Fix them one at a time and re-run all paths.

---

### ✅ Pattern 8: Final validation (the last 10 minutes before the freeze)

```
Run practiceRace('Path', 'all') and show time, penalties, energy and score for
each path, and the overall score.

Then list anything in the controller that could fail on a new layout
(edge cases, assumptions). Don't change anything.
```

**You decide:** is it ready? Then run `submitCar` yourself. You can resubmit until the freeze.

---

## Anti-patterns: what not to do

### ❌ Letting the agent decide
```
❌ "Which design should I pick?"  →  "Candidate C. Shall I update carDesign.m?"  →  "OK."
✅ "Here are my two candidates and my predictions. Show me the numbers and where I was wrong."
```
If the only thing you typed was "OK", you weren't the engineer for that decision.

### ❌ Letting the agent write your explanation
```
❌ Copying the agent's "trade-off explanation for your report" into your log.
✅ Write it yourself, then: "Check this against the numbers. Don't rewrite it."
```
The judges read your log, and they will ask you about it.

### ❌ Vague requests
```
❌ "Make the car faster."
✅ "Estimate curvature from previewPoints and use eq. 6 for the target speed in corners.
    Keep the drag strip stop-box logic. I expect the technical time to drop by a few seconds."
```

### ❌ Trusting output without running it
```
❌ "The agent implemented it, so it must work."
✅ Always run practiceRace after a change. If the agent didn't, type: "Run it and show me the numbers."
```

### ❌ "Fix it" without data
```
❌ "The car crashed. Fix it."
✅ "The car runs wide at the second hairpin. I think it brakes too late (eq. 5). Run the
    race-debrief skill on the technical path and tell me whether the data agree."
```

### ❌ Too many changes at once
```
❌ "Rewrite the whole controller with a new algorithm and also add adaptive speed."
✅ One change. Run the race. Did it improve? Keep or undo. Then the next change.
```

### ❌ Ignoring the final paths
```
❌ Optimising purely for the practice layouts.
✅ Ask regularly: "Will this work on a path with different corner radii, directions and straight lengths?"
```

---

## What the agent can and can't do

It can **read** every file in this folder, **edit** the files in `student/`, and **run MATLAB** through the `matlab`
MCP server (`garage`, `practiceRace`, `plotLap`, any MATLAB command), then read the output back to you. It has two
skills for this project: `car-design-review` and `race-debrief`.

It cannot (and must not) modify `simulator/` or `tracks/`, see the final paths, or change the vehicle physics.

When it goes off the rails, the **Taking back control** prompts in [README.md](README.md) bring it back.

---

## Tips

1. **Predict before every run.** One sentence is enough. Being wrong is how you learn something.
2. **Be specific about constraints:** "no penalties on any path" is clearer than "don't go off track".
3. **Ask for options, then choose:** "three ways to…" beats "the best way to…".
4. **Ask for the reasoning:** "Why should this help? Which equation?"
5. **Challenge the output:** "Where would this fail?"
6. **Use the data:** `plotLap` exists so you diagnose from telemetry, not from guesses.

---

*The agent is your pit crew. You are the race engineer. It makes your loop faster; it doesn't do your thinking.*
