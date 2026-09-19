# Submissions Folder

This folder holds team controller submissions for the championship evaluation.

## Expected Structure

```
submissions/
  TeamAlpha/
    controller.m       ← required
    robotConfig.m      ← optional (defaults used if missing)
  TeamBeta/
    controller.m
    robotConfig.m
  ...
```

## How to Submit

1. Create a folder with your team name (no spaces, e.g. `TeamAlpha`)
2. Copy your `student/controller.m` into it
3. Copy your `student/robotConfig.m` into it (optional but recommended)

## How the Evaluator Uses These Files

The instructor runs:
```matlab
evaluateAll('mystery')
```

Each team's `controller.m` is called in isolation. The `controller(obs, config)` interface is identical to the one you use in `practiceRace`. Your controller will run on the **mystery track** — a different layout that tests whether your solution generalises beyond the practice circuit.

## Scoring

```
Score = LapTime  +  5 × OffTrackExits  +  10 × BarrierContacts
```

- **Lower = better**
- DNF if the lap is not completed within 180 seconds
- DNF teams are ranked last

## Tips for a Good Submission

- Run `practiceRace('Headless', true)` at least 3 times before submitting
- Use `plotLap` to check your cross-track error stays inside the boundaries
- Ask your agent: *"Review my controller for anything that might fail on an unseen track"*
- Avoid hard-coded coordinates or constants that only work for the practice circuit
