# AI Grand Prix Workshop
## Agentic AI for Electrical Engineering with MATLAB

**Workshop concept:** Students use an AI coding/engineering agent connected to MATLAB through MCP to develop, test, improve, and race an autonomous virtual robot car.

**Target audience:** Electrical Engineering students, approximately second year through fourth year / Levels 4–7.

**Duration:** 2 hours

**Core theme:** *Build what you need with AI rather than being taught every implementation step.*

---

# 1. Workshop Vision

The workshop is designed to introduce students to **agentic engineering**.

The objective is **not** to teach a complete robotics or control course in two hours. Instead, students are given a working engineering environment and a clearly defined challenge. They use an AI agent as an engineering assistant to understand the system, choose an approach, implement a controller, test it in MATLAB, diagnose failures, and improve it.

The workshop should feel more like an engineering competition than a traditional MATLAB tutorial.

The central challenge is:

> **Build the fastest autonomous robot car that can successfully complete an unseen race track.**

Students develop their controllers on a practice track. At the end of the workshop, the controllers are evaluated on a **mystery track** that students have not seen beforehand.

The final race creates a visible and competitive outcome while demonstrating an important engineering principle:

> A solution that works on one test case is not necessarily a good general engineering solution.

---

# 2. Main Learning Objective

The most important skill students should leave with is:

> **How to turn an engineering requirement into a working system using an AI agent, MATLAB, simulation, testing, and iterative engineering judgment.**

The workshop is therefore primarily about:

- problem specification;
- working effectively with an AI engineering agent;
- understanding an existing engineering project;
- decomposing a problem into components;
- asking the agent to investigate possible approaches;
- implementing and testing ideas;
- evaluating whether AI-generated engineering decisions make sense;
- debugging and improving a design;
- validating a solution against a new scenario.

It is **not primarily about**:

- memorising MATLAB syntax;
- learning robotics theory from first principles;
- deriving vehicle equations;
- learning a specific control algorithm;
- learning networking;
- learning ROS;
- writing the complete simulator.

---

# 3. Why a Robot Racing Challenge?

A robot race provides several advantages for a mixed-level engineering audience.

## 3.1 Immediate visual feedback

Students immediately understand the outcome.

- Robot follows the track → good.
- Robot leaves the track → bad.
- Robot completes the lap slowly → improvement is possible.
- Robot completes the lap faster → the design improved.

This means students can reason about performance even if they have different levels of control or robotics knowledge.

## 3.2 Natural engineering trade-offs

Students must balance:

- speed;
- stability;
- steering performance;
- cornering;
- acceleration;
- generalisation.

Simply increasing the maximum speed should not automatically produce a better result.

## 3.3 Suitable for different student levels

A junior student may create a simple controller using heading error and speed reduction.

A more advanced student may implement:

- Pure Pursuit;
- curvature-based speed planning;
- adaptive look-ahead;
- PID control;
- Stanley control;
- model predictive control;
- trajectory optimisation.

All students can participate in the same race even if their solutions have very different levels of sophistication.

## 3.4 Good use of an AI agent

The problem naturally creates an agentic workflow:

```text
Engineering objective
        ↓
Ask AI agent to inspect the project
        ↓
Choose / investigate an approach
        ↓
Agent modifies MATLAB code
        ↓
MATLAB runs the simulation
        ↓
Observe the result
        ↓
Diagnose the problem
        ↓
Improve the controller
        ↓
Run again
```

---

# 4. Workshop Philosophy

The students should **not** receive a step-by-step solution.

They should receive:

1. a working simulator;
2. a robot model;
3. a practice track;
4. a controller interface;
5. a clear engineering specification;
6. examples of useful ways to work with an AI agent.

The students are then responsible for developing the autonomous racing logic.

The message of the workshop should be:

> **You do not need to know every command before you begin. You need to understand the problem, specify what you need, ask useful questions, test the result, and judge whether the solution is correct.**

---

# 5. Proposed Workshop Title

Recommended title:

# **Prompt. Build. Race.**
## Agentic AI for Electrical Engineering with MATLAB

Alternative titles:

- **AI Grand Prix — Build an Autonomous Racer with MATLAB Agents**
- **From Prompt to Motion — Agentic Engineering with MATLAB**
- **Build It with AI — Autonomous Racing Challenge**
- **AI Engineer for a Day — MATLAB Robot Racing Challenge**

---

# 6. Student Challenge

Each team receives the same starting project.

Their mission is:

> Develop an autonomous controller that allows the virtual robot car to complete the race track as quickly as possible without leaving the track.

The controller must also work on a **previously unseen final track**.

Students are encouraged to use the AI agent to:

- inspect the project;
- explain unfamiliar code;
- propose control strategies;
- implement algorithms;
- run MATLAB;
- analyse race results;
- identify failure modes;
- modify parameters;
- improve generalisation;
- create debugging plots;
- test different approaches.

---

# 7. What Students Should NOT Build

To keep the workshop achievable in two hours, the following components should already be provided.

Students should **not** need to build:

- the race simulator;
- numerical integration;
- basic vehicle physics;
- track rendering;
- collision detection;
- timing;
- scoring;
- networking;
- race-server logic;
- leaderboard infrastructure;
- MATLAB-to-network communication;
- the mystery track.

These are instructor-owned components.

---

# 8. What Students ARE Responsible For

Students should mainly work on the autonomous racing system.

The required components can be described to them as follows.

## 8.1 Steering control

The vehicle needs to determine:

> **Where should I steer?**

Useful information may include:

- robot position;
- heading;
- upcoming centre-line points;
- cross-track error;
- heading error;
- distance to upcoming waypoints;
- preview distance;
- track curvature.

Possible solutions may include:

- simple heading controller;
- PID;
- Pure Pursuit;
- Stanley controller;
- nonlinear control;
- MPC.

The workshop should not require students to use a particular method.

## 8.2 Speed control

The robot must determine:

> **How fast should I drive?**

A good system should generally behave differently on:

- long straights;
- gradual bends;
- sharp corners.

Students may investigate relationships between:

- speed;
- track curvature;
- steering demand;
- acceleration;
- braking distance;
- stability.

## 8.3 Corner handling

Students should consider the road ahead rather than reacting only when the robot reaches a corner.

For example:

```text
Straight road       → accelerate
Corner approaching  → reduce speed
Inside corner       → maintain safe speed
Corner exit         → accelerate again
```

## 8.4 Generalisation

Students must not hard-code individual corners or track coordinates from the practice track.

Their controller should interpret the provided observations and make decisions dynamically.

The final mystery track tests this requirement.

---

# 9. Student-Facing MATLAB Interface

The student project should expose one simple controller function.

Example:

```matlab
function command = controller(obs, config)

    % =====================================================
    % AI GRAND PRIX - AUTONOMOUS RACING CONTROLLER
    % =====================================================

    % Available observations may include:
    %
    % obs.position
    % obs.heading
    % obs.speed
    % obs.previewPoints
    % obs.trackWidth
    % obs.dt

    % Student / AI-generated implementation goes here.

    command.throttle = 0;
    command.steering = 0;

end
```

The exact interface should remain small and stable.

Students should be encouraged to create helper functions if their solution becomes more sophisticated.

---

# 10. Suggested Student Project Structure

```text
AI_Grand_Prix/
│
├── practiceRace.m             # Run local practice
├── joinRace.m                 # Connect to championship server
├── README.md                  # Student instructions
│
├── student/
│   ├── controller.m           # MAIN FILE TO MODIFY
│   └── robotConfig.m          # Optional limited configuration
│
├── simulator/
│   ├── Vehicle.m
│   ├── Track.m
│   ├── RaceSimulation.m
│   └── Visualizer.m
│
└── tracks/
    └── practiceTrack.mat
```

The simulator folder should either be protected or clearly marked:

> **DO NOT MODIFY**

For the competition, the official simulator should always run from the instructor-controlled copy.

---

# 11. Robot Model

A relatively simple car/robot model is preferable.

A lightweight 2-D kinematic model is sufficient for the educational objective.

Possible state:

\[
x,\quad y,\quad \theta,\quad v
\]

where:

- \(x,y\): vehicle position;
- \(\theta\): heading;
- \(v\): longitudinal velocity.

Possible controller outputs:

\[
a,\quad \delta
\]

where:

- \(a\): acceleration / throttle request;
- \(\delta\): steering request.

Alternatively, a differential-drive model could use:

\[
v,\quad \omega
\]

The car-like steering model may feel more natural for a racing competition.

---

# 12. Vehicle Constraints

The simulator should enforce physical limitations.

Example constraints:

```text
Maximum speed
Maximum acceleration
Maximum braking
Maximum steering angle
Maximum steering-rate
Optional maximum lateral acceleration
```

This prevents the trivial solution of commanding unlimited speed.

A simplified lateral acceleration constraint may be used:

\[
a_{lat} = v^2 |\kappa|
\]

where:

- \(v\) = vehicle speed;
- \(\kappa\) = path curvature.

If the robot attempts to corner too quickly, it may:

- leave the track;
- lose points;
- be considered unstable;
- receive a track violation.

The model does not need to be a high-fidelity tyre simulation.

---

# 13. Track Representation

The track should contain:

- centre-line points;
- track width;
- start/finish line;
- optional left/right boundaries;
- optional curvature information generated internally.

The students should receive only the information appropriate for their controller.

A useful observation may include a fixed number of upcoming centre-line points:

```matlab
obs.previewPoints
```

For example, the next 10–30 points ahead of the robot.

This naturally supports:

- look-ahead control;
- curvature estimation;
- predictive speed selection.

---

# 14. Practice Track and Mystery Track

Two categories of track should be used.

## 14.1 Practice track

Students have full access to this track.

They can:

- run it repeatedly;
- plot information;
- debug;
- optimise;
- allow the AI agent to inspect results.

The practice track should contain:

- straight sections;
- mild turns;
- at least one sharp turn;
- different corner directions.

## 14.2 Mystery track

Students do not see this track before the final evaluation.

It should be different but use the same underlying track format and physical rules.

Purpose:

- test generalisation;
- discourage hard-coded solutions;
- reward sound engineering.

Students should be told clearly from the beginning that the final track will be different.

---

# 15. Local Practice Mode

Most development should happen locally on each student's computer.

Command:

```matlab
practiceRace
```

The program should:

1. load the practice track;
2. initialise the vehicle;
3. repeatedly call the student's controller;
4. simulate vehicle motion;
5. visualise the vehicle;
6. calculate lap time;
7. identify track violations;
8. show the final score.

Example result:

```text
Team: Flux Capacitor

Lap completed: YES
Lap time:       36.28 s
Track exits:    1
Collisions:     0
Penalty:        5.00 s

Final score:    41.28
```

Students should be able to run the practice simulation as many times as they want.

---

# 16. Network Race Architecture

The final race can use a local network.

The instructor computer runs the official race server.

```text
                         INSTRUCTOR PC

                 ┌────────────────────────┐
                 │      RACE SERVER       │
                 │                        │
                 │ Official Track         │
                 │ Official Physics       │
                 │ Timing                 │
                 │ Scoring                │
                 │ Visualisation          │
                 │ Leaderboard            │
                 └────────────┬───────────┘
                              │
                       Lab LAN / Wi-Fi
             ┌────────────────┼────────────────┐
             │                │                │
             ▼                ▼                ▼

         Team 1 PC        Team 2 PC        Team 3 PC

         MATLAB           MATLAB           MATLAB
         AI Agent         AI Agent         AI Agent
         controller.m     controller.m     controller.m
```

The students should not need to understand the networking implementation.

---

# 17. Network Communication Model

At each simulation step the server sends an observation to each team.

Example observation:

```json
{
  "type": "observation",
  "carID": 4,
  "x": 12.3,
  "y": 4.8,
  "heading": 1.23,
  "speed": 3.1,
  "trackWidth": 2.0,
  "previewPoints": [
    [12.5, 5.0],
    [13.1, 5.4],
    [13.8, 6.0]
  ],
  "dt": 0.02
}
```

The student computer evaluates:

```matlab
command = controller(observation, config);
```

and returns:

```json
{
  "type": "command",
  "throttle": 0.72,
  "steering": -0.18
}
```

The instructor server then updates the official simulation.

---

# 18. Why TCP is a Good Choice

For the first version, TCP is preferable because:

- communication is reliable;
- debugging is easier;
- packet ordering is guaranteed;
- students do not need high-frequency real-time control;
- MATLAB has built-in TCP client/server functionality.

The networking layer should be hidden inside:

```matlab
joinRace(...)
```

Students should not have to write networking code.

---

# 19. Fairness and Network Latency

The race should **not** use network latency as part of simulation time.

For example, use a fixed simulation step:

\[
\Delta t = 0.02~s
\]

The server should conceptually operate as:

```text
Simulation time = 10.00 s

Send observations
        ↓
Receive controller outputs
        ↓
Update every robot using dt = 0.02
        ↓
Simulation time = 10.02 s
```

Therefore, a slightly slower laptop or wireless connection does not directly make the simulated car slower.

A reasonable controller-response timeout should still exist to stop a broken controller from blocking the race.

---

# 20. Live Race vs Official Evaluation

A useful approach is to separate:

## 20.1 Live race

Students connect from their laptops.

All cars appear on the same projected track.

This provides:

- excitement;
- audience engagement;
- competition;
- live debugging;
- a visual finale.

## 20.2 Official prize evaluation

At the deadline, each team submits its final:

```text
controller.m
```

The instructor then runs all controllers locally on the **same computer** using:

- the same MATLAB version;
- the same vehicle model;
- the same mystery track;
- the same time step;
- the same CPU environment.

This eliminates unfair differences caused by:

- network latency;
- computer performance;
- background processes;
- wireless reliability.

The official prize result should preferably come from this central evaluation.

---

# 21. Multi-Car Visualisation

During the championship, all cars can be displayed simultaneously on the projector.

Example:

```text
                    AI GRAND PRIX

             Team Tesla       ●
                             /
                    ●-------/
              Team GaN

        ╭──────────────────────────╮
        │                          │
        │          Track           │
        │                          │
        ╰──────────────────────────╯


LIVE STANDINGS

1. Team Tesla          31.72 s
2. Team GaN            +1.35 s
3. Flux Capacitor      +2.82 s
4. Control Freaks      +4.18 s
```

Cars should preferably **not collide with each other**.

They should behave like visual "ghost" cars so that one team cannot interfere with another team's performance.

---

# 22. Scoring

The scoring system should be understandable.

A simple example:

\[
Score =
T_{lap}
+
5N_{offtrack}
+
10N_{collision}
\]

where:

- \(T_{lap}\): lap completion time;
- \(N_{offtrack}\): number of track violations;
- \(N_{collision}\): collision / severe violation count.

Lowest score wins.

A robot that fails to complete the course receives:

> **DNF — Did Not Finish**

The exact penalties should be tested before the workshop to make sure they do not create strange incentives.

---

# 23. Possible Awards

Using more than one award is strongly recommended.

## 🏁 Fastest Robot

Best official competition score.

## 🧠 Best Engineering Solution

Awarded for a thoughtful, robust, or interesting control strategy.

## 🤖 Best Use of AI Agent

Awarded to the team that demonstrates particularly effective use of the AI agent for:

- investigation;
- modelling;
- testing;
- debugging;
- validation;
- improvement.

## 💡 Optional: Most Creative Solution

Useful if several groups take very different approaches.

This avoids making the workshop only about raw speed.

---

# 24. Suggested Two-Hour Schedule

## 0–10 min — Introduction

Explain:

- what an AI agent is;
- what MCP provides;
- how the agent can interact with MATLAB;
- the difference between asking a chatbot a question and allowing an agent to execute engineering tasks.

Keep slides minimal.

## 10–20 min — Live Agent Demonstration

Demonstrate the complete loop:

```text
Prompt
  ↓
AI agent edits controller
  ↓
MATLAB runs race
  ↓
Robot fails / improves
  ↓
Agent analyses result
  ↓
Agent modifies controller
  ↓
Race runs again
```

A deliberately imperfect first attempt is useful.

This shows that:

> AI-generated code is a prototype that still requires engineering evaluation.

## 20–30 min — Explain the Competition

Explain:

- robot model;
- controller inputs;
- controller outputs;
- vehicle constraints;
- practice track;
- mystery track;
- scoring;
- rules;
- submission process.

Do **not** give a control-theory lecture.

## 30–75 min — Development Session

Approximately 45 minutes.

Students:

- inspect the provided project;
- discuss approaches with the AI agent;
- implement a controller;
- test locally;
- analyse performance;
- iterate.

Tutors circulate and assist.

Tutors should focus on helping students:

- define the problem;
- ask better questions;
- interpret results;
- understand failures.

Avoid simply writing the solution for them.

## 75–90 min — Qualification / Practice Leaderboard

Teams run a qualifying race on the practice environment.

Display provisional times.

This creates urgency and encourages refinement.

## 90–105 min — Final Development Sprint

Students have approximately 15 minutes to improve their controller.

At the end:

> **Code freeze.**

Each group submits its final controller.

## 105–120 min — Mystery Track Championship

Reveal the mystery track.

Run:

1. live race / visual competition;
2. official evaluation;
3. leaderboard;
4. awards / gifts.

---

# 25. Recommended Student Instructions

The printed instruction sheet should explain the required system components without telling students exactly how to implement them.

Example wording:

> Your robot must make two main decisions continuously:
>
> **1. Where should I steer?**
>
> **2. How fast should I drive?**
>
> Your controller receives information about the vehicle and the upcoming section of the race track.
>
> Use your AI engineering agent to investigate possible control approaches, implement a solution, run the simulation, analyse failures, and improve performance.

Students should be explicitly told:

> You are not expected to already know the best algorithm.

---

# 26. Example Prompts Students Can Use

Students should receive examples of **good engineering-agent interaction**, not a solution.

### Understanding the project

```text
Read the MATLAB project before making changes.
Explain the simulator, controller interface, available observations,
vehicle constraints, and the files I am expected to modify.
```

### Investigating approaches

```text
I need an autonomous controller that can follow an unknown race track.
Propose three suitable steering-control approaches and explain the
advantages and disadvantages of each for this project.
```

### Initial implementation

```text
Implement the simplest robust approach using the existing controller
interface. Do not modify the simulator.
```

### Diagnosing a failure

```text
Run the practice race and analyse why the vehicle leaves the track
during sharp corners. Use simulation results rather than guessing.
```

### Improving speed control

```text
Investigate whether upcoming track curvature can be estimated from
previewPoints and used to choose an appropriate target speed.
```

### Improving generalisation

```text
Review the controller for assumptions that are specific to the current
practice track. Modify it so that it is more likely to work on an
unseen track.
```

### Validation

```text
Create tests or plots that help verify that the steering and speed
controllers behave sensibly for straights, gentle corners, and sharp
corners.
```

---

# 27. What We Want Students to Learn About AI

Several messages should be deliberately reinforced.

## 27.1 AI works better with clear requirements

Compare:

```text
Make the car fast.
```

with:

```text
Improve lap time while preventing the vehicle from leaving the track.
Use upcoming path curvature to reduce target speed before sharp corners.
```

The second request contains engineering intent.

## 27.2 The agent should inspect before editing

Students should learn to ask the agent to understand:

- project structure;
- interfaces;
- constraints;
- existing code.

before changing the system.

## 27.3 AI output must be tested

Students should not assume:

> The code ran, therefore the engineering is correct.

They should observe:

- trajectory;
- speed profile;
- steering;
- lap time;
- failures;
- constraint violations.

## 27.4 Engineering judgment remains important

Students should question:

- assumptions;
- physical plausibility;
- robustness;
- edge cases;
- whether the solution is overfitted.

## 27.5 Iteration is normal

A strong engineering workflow is:

```text
Prototype
   ↓
Test
   ↓
Observe
   ↓
Diagnose
   ↓
Improve
   ↓
Validate
```

The AI agent accelerates this loop; it does not remove the need for it.

---

# 28. MATLAB / MathWorks Components That Can Be Reused

The implementation should reuse existing MATLAB capabilities wherever practical.

Potential foundations include:

- MATLAB;
- Simulink, if desired;
- Robotics System Toolbox;
- Navigation Toolbox;
- Mobile Robotics Simulation Toolbox;
- `controllerPurePursuit`;
- vehicle / mobile-robot kinematic models;
- occupancy maps;
- App Designer;
- TCP/IP communication;
- JSON encoding/decoding.

The recommended first version should remain **2-D and lightweight**.

Avoid requiring:

- Unreal Engine;
- photorealistic simulation;
- ROS;
- complex 3-D sensors;
- high-fidelity vehicle dynamics;

unless the workshop is expanded later.

---

# 29. Recommended Baseline Controller

Every team should begin with a controller that already completes the practice track slowly.

For example:

- low fixed speed;
- simple Pure Pursuit;
- conservative look-ahead distance.

This means no group becomes completely stuck.

The challenge becomes:

> **Make it better.**

rather than:

> **Make anything work at all.**

This also creates natural AI-agent questions such as:

- Why does Pure Pursuit cut corners?
- How should look-ahead distance depend on speed?
- How can upcoming curvature be estimated?
- How should target speed change before a corner?
- Is the controller oscillating?
- How can we tune it automatically?

---

# 30. Optional Robot Configuration

Students may be allowed limited configuration choices.

Example:

```matlab
config.maxSpeed
config.maxAcceleration
config.maxSteering
config.lookaheadRange
```

However, design variables must have strict bounds.

For the first workshop, it may be better to keep the physical robot identical for all teams and make the competition entirely about autonomous control.

A later version could introduce a design budget in which teams allocate limited resources to:

- motor power;
- sensor range;
- steering;
- acceleration.

---

# 31. Instructor Race-Control Application

An instructor application can eventually be built using MATLAB App Designer.

Possible layout:

```text
┌────────────────────────────────────────────┐
│              AI GRAND PRIX                 │
│                                            │
│ Connected teams: 12 / 14                   │
│                                            │
│ ✓ Team Tesla             Ready             │
│ ✓ Flux Capacitor         Ready             │
│ ✓ Team GaN               Ready             │
│ ○ Team Control           Waiting           │
│                                            │
│ Mode:  [Practice] [Qualifying] [FINAL]     │
│                                            │
│ Track: Mystery Track 01                    │
│                                            │
│               [ START RACE ]               │
│                                            │
│ LEADERBOARD                                │
│ 1. Team Tesla               31.82          │
│ 2. Team GaN                 32.17          │
│ 3. Flux Capacitor           35.48          │
└────────────────────────────────────────────┘
```

Functions may include:

- team registration;
- connection monitoring;
- start/stop race;
- choose track;
- code-freeze indicator;
- live track display;
- leaderboard;
- export results.

---

# 32. Possible Technical Architecture

```text
                    DEVELOPMENT

                 Student + AI Agent
                         │
                    MATLAB MCP
                         │
                  controller.m
                         │
                         ▼
                 Local Practice Race


                    CHAMPIONSHIP

 Student 1 ───────┐
 Student 2 ───────┤
 Student 3 ───────┤
 Student 4 ───────┤
                  │
                  ▼
             Race Server
                  │
       ┌──────────┼──────────┐
       │          │          │
       ▼          ▼          ▼
   Physics      Track      Timing
       │          │          │
       └──────────┼──────────┘
                  ▼
              Visualiser
                  │
                  ▼
             Leaderboard
```

---

# 33. Optional ABB YuMi Demonstration

The ABB IRB 14000 YuMi in the laboratory can still be useful, but it should **not** become the main activity.

A short demonstration near the end can show that the same agentic engineering concept extends from simulation to real physical systems.

Possible message:

> Today you used an AI agent to build and test a controller in simulation. The same workflow can be connected to real engineering hardware, provided that simulation, validation, safety checks, and human approval are placed between the AI agent and the physical machine.

The YuMi demonstration should be pre-tested and instructor controlled.

It is optional and should not consume time needed for the race.

---

# 34. Safety and Responsible Agent Use

Even though the main competition is simulated, students should be introduced briefly to an important engineering principle:

> **AI agents should not receive unrestricted control of safety-critical physical systems.**

For physical hardware, the preferred workflow is:

```text
AI proposes / generates
        ↓
Simulation
        ↓
Validation
        ↓
Engineering review
        ↓
Human approval
        ↓
Physical deployment
```

This is particularly important if the workshop ends with a real-robot demonstration.

---

# 35. Workshop Preparation Checklist

## Instructor software

- MATLAB installed;
- required MathWorks toolboxes installed;
- MATLAB MCP server installed/configured;
- chosen AI agent available;
- race project tested;
- network connectivity tested.

## Student software

Confirm beforehand:

- MATLAB version;
- required toolbox licences;
- MCP setup;
- AI-agent availability;
- network permissions;
- firewall settings.

A setup guide should be sent before the workshop if possible.

## Race infrastructure

Prepare:

- practice track;
- at least one mystery track;
- baseline controller;
- scoring;
- DNF rules;
- network server;
- submission method;
- leaderboard;
- backup offline race method.

## Physical room

Recommended:

- projector;
- instructor computer;
- shared lab LAN / Wi-Fi;
- visible leaderboard;
- tutors / helpers if many students attend.

---

# 36. Important Reliability Requirement

The workshop must not depend entirely on the live network.

A backup mode should exist.

If networking fails:

1. teams submit `controller.m`;
2. instructor runs each controller centrally;
3. results are projected;
4. competition continues.

The educational objective remains intact even if the live multiplayer feature fails.

---

# 37. Development Priorities

The system should be developed in stages.

## Phase 1 — Single-car local simulator

Goal:

```matlab
practiceRace
```

runs a car around one track.

Required:

- track;
- vehicle;
- controller interface;
- timing;
- visualisation.

## Phase 2 — Baseline controller

Create a conservative controller that completes the track.

This becomes the student starting point.

## Phase 3 — Scoring

Implement:

- lap completion;
- timing;
- off-track detection;
- penalties;
- DNF.

## Phase 4 — Mystery-track validation

Create multiple tracks and confirm that good generic controllers can complete them.

## Phase 5 — Student package

Create:

- README;
- controller template;
- practice project;
- setup instructions.

## Phase 6 — Central evaluator

Instructor can load multiple student controllers and run them under identical conditions.

## Phase 7 — Network race

Implement:

- race server;
- student client;
- team registration;
- observation/command communication;
- multiplayer visualisation.

## Phase 8 — Instructor dashboard

Add:

- App Designer interface;
- team status;
- race control;
- leaderboard.

---

# 38. Minimum Viable Version

A successful first workshop does **not** require the complete network system.

The minimum viable system is:

```text
Practice simulator
      +
Baseline controller
      +
Student controller interface
      +
Mystery track
      +
Central evaluation
      +
Leaderboard
```

Students can simply submit their controller files before the championship.

The network multiplayer mode can be added after the basic workshop is stable.

This is the lowest-risk implementation path.

---

# 39. Recommended Final Architecture

```text
                       BEFORE WORKSHOP

                    Instructor prepares
                           │
       ┌───────────────────┼──────────────────┐
       ▼                   ▼                  ▼
    Simulator         Practice Track      Mystery Tracks


                        WORKSHOP

                    Student / Team
                         │
                         ▼
                     AI Agent
                         │
                    MATLAB MCP
                         │
                         ▼
                    controller.m
                         │
                         ▼
                 Local Practice Race
                         │
                         ▼
                      Improve


                         FINAL

                  Controller frozen
                         │
             ┌───────────┴───────────┐
             ▼                       ▼
         Live LAN race        Official evaluator
                                      │
                                      ▼
                                Mystery track
                                      │
                                      ▼
                                  Leaderboard
                                      │
                                      ▼
                                    Gifts
```

---

# 40. Success Criteria for the Workshop

The workshop should be considered successful if students leave able to say:

- I can give an AI agent an engineering requirement rather than only ask coding questions.
- I can ask an agent to inspect and understand an existing project.
- I can ask it to propose different engineering approaches.
- I can make it modify and run MATLAB code.
- I can use simulation results to diagnose problems.
- I understand that AI-generated engineering output must be verified.
- I can iteratively improve a working engineering system.
- I understand the difference between fitting one example and building a solution that generalises.

The race is the mechanism used to teach these skills.

---

# 41. Final Workshop Message

The central message of the workshop should be:

> **AI does not replace engineering. It changes how quickly an engineer can move from an idea to a testable implementation.**

Students are still responsible for:

- defining the problem;
- identifying constraints;
- deciding whether results make sense;
- recognising failures;
- validating the final design.

The desired student experience is:

> **Prompt → Build → Test → Fail → Diagnose → Improve → Race**

That captures the purpose of the workshop better than a conventional MATLAB or robotics tutorial.
