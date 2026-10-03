# Topics and the draw (instructor)

## Before the workshop
- Edit **`topic_pool.csv`**: one row per topic (`id, title, keywords, matlab_angle`). The 20 rows are a **draft**: change them to fit
  your students' field. `matlab_angle` is the experiment the student's proposal will leave **pending**, so keep topics that MATLAB can test.
- You need at least as many topics as people/groups who choose the pool.

## On the day: inside the presentation (main way)
Open **`instructor/presentation/index.html`** (the local slide viewer). Slide **"Drawing lots, live"** *is* the draw:
add names (Pool / Own topic), **Draw lots**, reveal with **Space / →**, then **Save assignments.csv**. Works offline; the list is
remembered in that browser. The topics come from `topic_pool.csv`: after editing it, rebuild the viewer with
`python build_preview.py` (in `instructor/presentation`).

## Alternative: the online Topic Draw page
**https://claude.ai/artifact/Kqoie5VeZBXJkag3DCoUqx** (also linked from the deck's topic slides). Private to you; your entries are saved.
1. Show the **topic slide**: each student or group chooses **own topic** or **join the pool**.
2. On the page, add each name or group as **Pool** or **Own topic** (with their topic). *Paste a list of names* adds many to the pool at once.
3. Press **Draw lots**. On the projector, Space / → reveals the next name and topic. The seed is shown and stored.
4. **Download assignments.csv** or **Copy as text** and share it.
5. Each student copies their topic into **`AI_Tools/1_topic/my_topic.md`** and starts with `Run the research-question skill`.
To redo: **Reset draw** (click twice). The 20 topics are loaded on the page; add or remove topics there before drawing.

## Offline fallback: MATLAB
Fill **`participants.csv`** (`name, choice, own_topic`; `choice` = `pool` or `own`), then run **`draw_lots`** in this folder.
Same reveal on the projector; writes `assignments.csv`. `draw_lots(<seed>)` repeats a draw; `draw_lots([], false)` skips the animation.
