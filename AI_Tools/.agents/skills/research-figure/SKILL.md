---
name: research-figure
description: Make the proposal's figure with PaperViz, Google Research's figure method (Planner → Stylist → Visualizer → Critic), drawn with your own built-in image generation. Reads the Figure brief in 5_proposal/proposal.md and saves the figure in 5_proposal/figure/. Use after literature-review has written the proposal, when the student asks for the figure. No API key needed.
---

# Figure with PaperViz (step 5)

PaperViz is Google Research's method for academic figures (github.com/google-research/papervizagent). You run its four agents
yourself, using the prompts in [prompts.md](prompts.md) and the style rules in [style_guide.md](style_guide.md), and you draw the
image with **your own built-in image generation tool**. No API key, no extra install.

**Inputs:** in `5_proposal/proposal.md`, the method / idea section (= PaperViz's *Methodology Section*) and the **Figure brief**
(= PaperViz's *Figure Caption*). **Outputs:** only in `5_proposal/figure/`: the image, plus `<name>_description.md` with the final
description. Never overwrite an existing file: add `_v2`, `_v3`.

## 0. Plan with the student
Read both inputs. In 3–4 lines tell the student what the figure will show (elements, arrows, labels, the one message) and ask them
to confirm or correct it. Pick a short file name, e.g. `figure_method`.

## 1. Planner
Follow the **Planner** prompt in `prompts.md`: from the methodology and the caption, write a *detailed* description of the figure:
every element and connection, layout, background, colors, line thickness, icon style. No figure title inside the image.

## 2. Stylist
Follow the **Stylist** prompt with `style_guide.md`: refine the look only (shapes, palette, typography, background).
Do not change the content.

## 3. Visualizer
Generate the image with your built-in image generation tool, using the **Visualizer** request in `prompts.md` with the stylist's
description, landscape 16:9. Save it as `5_proposal/figure/<name>.png`.

## 4. Critic (at most 2 rounds)
Look at the image and follow the **Critic** prompt: is it faithful to the methodology and the caption, are the labels spelled
right, is anything invented, is the caption text kept out of the image? If the critique is "No changes needed.", stop. Otherwise
generate again from the revised description (step 3) and save as `_v2` (then `_v3`).

## 5. Finish
Save the final description as `5_proposal/figure/<name>_description.md`. Show the student the image and your critique notes.
Add under the Figure brief in `5_proposal/proposal.md`: `Figure: figure/<file name> (PaperViz)`. Then say:
"Next: run the research-report skill."

If you have no image generation tool, say so plainly and stop; don't fake an image.
Generated figures can contain wrong labels or invented details: the student must check them before using them anywhere.
