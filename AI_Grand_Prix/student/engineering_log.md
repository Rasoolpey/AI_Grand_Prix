# Engineering log — Team ____________

> **This is your file.** You write the guesses, predictions, decisions and explanations, in your own words.
> The agent reads it so it knows what you decided. It may fill in only the **📏 measured** fields, and only when you ask.
> `submitCar` hands it in with your best model, and the judges read it for 🧠 *best engineering explanation* and
> 🤖 *best use of the agent*.

---

## 1. Meet your car (you run this yourself, in MATLAB)

`garage`, then `practiceRace` (watch it), then `practiceRace('Path', 'all')`.

| Path | Time (s) | Penalties (s) | Score |
|---|---|---|---|
| Drag strip | | | |
| Technical | | | |
| Endurance | | | |
| Muddy road | | | |
| **Overall** | | | |

My **weakest path** is ____________ . I think it's slow because (which part or which part of the driving, which equation):

>

---

## 2. Car design

### My candidates: write these *before* you ask the agent for numbers

| | Change from my current car | What I expect gets **better** (path, equation) | What I expect gets **worse** (path, equation) |
|---|---|---|---|
| A | none (current car) | | |
| B | | | |
| C | | | |

### 📏 The numbers (the agent can fill this in with the `car-design-review` skill)

| | Cost | Mass | Est. drag (s) | Est. technical (s) | Est. endurance (s) | Est. mud (s) | Est. overall | Weakest path |
|---|---|---|---|---|---|---|---|---|
| A | | | | | | | | |
| B | | | | | | | | |
| C | | | | | | | | |

**Was my prediction right?** Where was I wrong, and which equation explains it?

>

### My decision

I race design ____ because

>

**My trade-off** (3–4 sentences, with numbers, in my own words; this is the written deliverable):

>

---

## 3. Driving strategy

The options the agent gave me (one line each):

-
-
-

I chose ____________ because

>

---

## 4. Change log: one change, one run, one row

| # | Path | What I think is limiting the car, and why | The change I approved | 📏 Before → after (time, penalties, overall) | New best? | Keep or revert? |
|---|---|---|---|---|---|---|
| 1 | | | | | | |
| 2 | | | | | | |
| 3 | | | | | | |
| 4 | | | | | | |
| 5 | | | | | | |

---

## 5. Before I submit

- [ ] No practice coordinates, corner positions, lap distances or path-specific timings in `controller.m` (AGENT_GUIDE, Pattern 7)
- [ ] Team name and colour set in `carDesign.m` (the name on race day)
- [ ] `bestModel` shows my best model, with my team name. Overall: ______
- [ ] I can explain every change in section 4 without looking at the agent's replies
- [ ] `submitCar` run
