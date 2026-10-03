"""Build an offline browser viewer from project/deck.json and slide fragments.

The slide with id "p1-draw" becomes the interactive topic draw in this viewer; its topics come from
../topics/topic_pool.csv. Re-run this script after changing slides or topics:  python build_preview.py
"""

import csv
import html
import json
from pathlib import Path


def build():
    root = Path(__file__).resolve().parent
    project = root / "project"
    deck = json.loads((project / "deck.json").read_text(encoding="utf-8"))
    slides = []
    for slide_id in deck["order"]:
        source = project / "slides" / f"{slide_id}.html"
        slides.append({"id": slide_id, "html": source.read_text(encoding="utf-8")})
    payload = json.dumps(slides, ensure_ascii=False).replace("<", "\\u003c")
    topics_file = root.parent / "topics" / "topic_pool.csv"
    topics = []
    if topics_file.exists():
        with topics_file.open(encoding="utf-8", newline="") as f:
            topics = [{"id": int(r["id"]), "title": r["title"].strip(), "keywords": (r.get("keywords") or "").strip()}
                      for r in csv.DictReader(f) if (r.get("id") or "").strip().isdigit() and (r.get("title") or "").strip()]
    topics_payload = json.dumps(topics, ensure_ascii=False).replace("<", "\\u003c")
    title = html.escape(deck["title"])
    page = TEMPLATE.replace("__TITLE__", title).replace("__TOPICS__", topics_payload).replace("__SLIDES__", payload)
    output = root / "index.html"
    output.write_text(page, encoding="utf-8")
    print(f"Built {output} ({len(slides)} slides, {len(topics)} topics in the draw)")


TEMPLATE = r'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>__TITLE__ — slide viewer</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@400..700&family=IBM+Plex+Sans:wght@400;600&family=JetBrains+Mono:wght@400;600&display=swap">
<style>
* { box-sizing: border-box; }
html, body { margin: 0; height: 100%; }
body { background: #0d1628; color: #f5f3ee; font: 15px Arial, sans-serif; display: flex; flex-direction: column; }
header { display: flex; align-items: center; flex-wrap: wrap; gap: 10px; padding: 12px 18px; border-bottom: 1px solid #334155; }
header strong { margin-right: auto; }
button, select { border: 1px solid #536279; background: #1e2b42; color: #fff; border-radius: 6px; padding: 8px 12px; font: inherit; }
button { cursor: pointer; }
button:disabled { opacity: .4; cursor: default; }
button:focus-visible, select:focus-visible, input:focus-visible { outline: 3px solid #7fd3c7; outline-offset: 2px; }
label { display: flex; align-items: center; gap: 5px; }
#stage { flex: 1; min-height: 120px; position: relative; overflow: hidden; margin: 12px; }
#canvas { width: 1920px; height: 1080px; position: absolute; transform-origin: top left; background: #f5f3ee; }
#canvas > section { display: none !important; width: 1920px; height: 1080px; position: relative; overflow: hidden; }
#canvas > section.active { display: flex !important; }
#canvas h1, #canvas h2, #canvas h3, #canvas p { margin: 0; }
#canvas table { border-collapse: collapse; width: 100%; }
#canvas th, #canvas td { padding: 15px 18px; border-bottom: 1px solid #d9d5ce; vertical-align: top; }
#canvas ul, #canvas ol { padding-left: 1.25em; margin: 0; }
#canvas li + li { margin-top: .35em; }
#canvas aside { display: none; }
#notes { max-height: 25vh; overflow: auto; background: #18243a; padding: 16px 24px; border-top: 1px solid #334155; line-height: 1.5; white-space: pre-wrap; }
#notes[hidden] { display: none; }
footer { padding: 8px 18px; font-size: 12px; color: #b9c6d8; }
body.presenting header, body.presenting footer, body.presenting #notes { display: none; }
body.presenting #stage { margin: 0; }
/* ---- interactive topic draw (slide p1-draw); sizes are on the 1920x1080 slide canvas */
#canvas > section.drawapp { background: #13203A; color: #F5F3EE; font-family: 'IBM Plex Sans', Arial, sans-serif; padding: 60px 112px 52px; flex-direction: column; gap: 18px; }
.drawapp .da-head { display: flex; align-items: flex-end; gap: 48px; }
.drawapp .da-eyebrow { font-family: 'JetBrains Mono', 'Courier New', monospace; font-size: 24px; letter-spacing: 2px; color: #7FD3C7; }
.drawapp .da-title { font-family: 'Space Grotesk', Arial, sans-serif; font-size: 56px; font-weight: 600; line-height: 1.1; }
.drawapp .da-stats { display: flex; gap: 36px; margin-left: auto; font-variant-numeric: tabular-nums; }
.drawapp .da-stats div { display: flex; flex-direction: column; }
.drawapp .da-stats b { font-family: 'Space Grotesk', Arial, sans-serif; font-size: 44px; line-height: 1; }
.drawapp .da-stats span { font-size: 20px; color: #9AA7BD; }
.drawapp .da-actions { display: flex; gap: 14px; flex-wrap: wrap; }
.drawapp .da-btn { font: 600 24px 'IBM Plex Sans', Arial, sans-serif; padding: 14px 24px; border-radius: 12px; background: #1D2D4C; border: 2px solid #2C3D60; color: #F5F3EE; }
.drawapp .da-btn:hover:not(:disabled) { border-color: #9AA7BD; }
.drawapp .da-primary { background: #FF8A3D; border-color: #FF8A3D; color: #13203A; font-family: 'Space Grotesk', Arial, sans-serif; font-size: 30px; padding: 16px 34px; }
.drawapp .da-armed { background: #FFC857 !important; border-color: #FFC857 !important; color: #13203A !important; }
.drawapp .da-note { font-size: 24px; color: #C9D3E3; }
.drawapp .da-body { display: grid; grid-template-columns: 1fr 1.55fr; gap: 32px; flex: 1; min-height: 0; }
.drawapp .da-pane { background: #16233D; border: 2px solid #2C3D60; border-radius: 18px; padding: 22px 28px; display: flex; flex-direction: column; gap: 14px; min-height: 0; }
.drawapp .da-h3 { font-family: 'Space Grotesk', Arial, sans-serif; font-size: 30px; font-weight: 600; }
.drawapp form { display: flex; flex-wrap: wrap; gap: 12px; }
.drawapp input, .drawapp textarea { font: 24px 'IBM Plex Sans', Arial, sans-serif; color: #F5F3EE; background: #0F1A2F; border: 2px solid #2C3D60; border-radius: 10px; padding: 12px 14px; flex: 1 1 340px; min-width: 0; }
.drawapp textarea { width: 100%; min-height: 150px; resize: vertical; }
.drawapp input::placeholder, .drawapp textarea::placeholder { color: #9AA7BD; }
.drawapp .da-choice { display: inline-flex; border: 2px solid #2C3D60; border-radius: 10px; overflow: hidden; }
.drawapp .da-choice button { font: 600 22px 'IBM Plex Sans', Arial, sans-serif; padding: 12px 18px; background: transparent; border: none; border-radius: 0; color: #C9D3E3; }
.drawapp .da-choice button.on[data-c="pool"] { background: #3FB8A6; color: #13203A; }
.drawapp .da-choice button.on[data-c="own"] { background: #FF8A3D; color: #13203A; }
.drawapp details summary { font-size: 22px; color: #9AA7BD; cursor: pointer; }
.drawapp details[open] { display: flex; flex-direction: column; gap: 10px; }
#canvas .drawapp .da-list { list-style: none; margin: 0; padding: 0; overflow: auto; flex: 1; min-height: 0; }
#canvas .drawapp .da-list li { display: grid; grid-template-columns: auto 1fr auto; gap: 16px; align-items: center; padding: 10px 0; border-top: 1px solid #2C3D60; margin: 0; }
#canvas .drawapp .da-list li:first-child { border-top: none; }
.drawapp .da-chip { font: 600 18px 'JetBrains Mono', 'Courier New', monospace; padding: 4px 10px; border-radius: 999px; color: #13203A; min-width: 70px; text-align: center; }
.drawapp .da-chip.pool { background: #3FB8A6; } .drawapp .da-chip.own { background: #FF8A3D; }
.drawapp .da-who { display: flex; flex-direction: column; min-width: 0; }
.drawapp .da-who b { font-size: 26px; font-weight: 600; overflow-wrap: anywhere; }
.drawapp .da-who small { font-size: 21px; color: #9AA7BD; overflow-wrap: anywhere; }
.drawapp .da-who small.got { color: #FFC27F; }
.drawapp .da-x { font: 18px 'IBM Plex Sans', Arial, sans-serif; background: none; border: 2px solid transparent; color: #9AA7BD; padding: 6px 12px; }
.drawapp .da-x:hover { border-color: #2C3D60; }
.drawapp .da-empty { color: #9AA7BD; font-size: 22px; display: block !important; }
#canvas .drawapp .da-topics { display: grid; grid-template-columns: 1fr 1fr; grid-template-rows: repeat(10, auto); grid-auto-flow: column; column-gap: 36px; row-gap: 2px; margin: 0; padding: 0; list-style: none; overflow-x: hidden; overflow-y: auto; flex: 1; min-height: 0; align-content: start; }
#canvas .drawapp .da-topics li { display: flex; gap: 12px; font-size: 20px; line-height: 1.2; padding: 3px 0; margin: 0; min-width: 0; }
#canvas .drawapp .da-topics li span { font: 600 19px 'JetBrains Mono', 'Courier New', monospace; color: #7FD3C7; min-width: 30px; padding-top: 2px; }
#canvas .drawapp .da-topics li.taken { color: #6E7C95; text-decoration: line-through; }
.drawapp .da-seed { font: 20px 'JetBrains Mono', 'Courier New', monospace; color: #9AA7BD; }
.drawapp .da-stage { position: absolute; inset: 0; background: #0F1A2F; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 44px; text-align: center; padding: 80px; z-index: 5; }
.drawapp .da-stage[hidden] { display: none; }
.drawapp .da-count { font: 28px 'JetBrains Mono', 'Courier New', monospace; color: #9AA7BD; letter-spacing: 3px; }
.drawapp .da-name { font-family: 'Space Grotesk', Arial, sans-serif; font-size: 112px; font-weight: 700; line-height: 1.05; max-width: 1500px; }
.drawapp .da-slip { background: #F5F3EE; color: #13203A; border-radius: 8px; padding: 32px 48px; max-width: 1500px; min-height: 150px; display: flex; align-items: center; gap: 28px; box-shadow: 0 24px 60px rgba(0,0,0,.4); transform: rotate(-1.2deg); }
.drawapp .da-slip .no { font: 600 40px 'JetBrains Mono', 'Courier New', monospace; color: #8A5A2B; }
.drawapp .da-slip .t { font-family: 'Space Grotesk', Arial, sans-serif; font-size: 60px; font-weight: 700; line-height: 1.15; text-align: left; }
.drawapp .da-slip.spinning { filter: blur(1.5px); opacity: .8; }
.drawapp .da-hint { font-size: 22px; color: #9AA7BD; }
@media (prefers-reduced-motion: reduce) { .drawapp .da-slip { transform: none; } .drawapp .da-slip.spinning { filter: none; } }
@media print {
  @page { size: 16in 9in; margin: 0; }
  html, body { height: auto; background: white; display: block; }
  header, footer, #notes { display: none !important; }
  #stage { margin: 0; overflow: visible; }
  #canvas { position: static; width: auto; height: auto; transform: none !important; }
  #canvas > section { display: flex !important; width: 1920px; height: 1080px; zoom: .8; break-after: page; print-color-adjust: exact; -webkit-print-color-adjust: exact; }
  #canvas > section:last-child { break-after: auto; }
  #canvas > section.excluded { display: none !important; }
}
</style>
</head>
<body>
<header>
  <strong>__TITLE__</strong>
  <button id="prev" aria-label="Previous slide">←</button>
  <select id="picker" aria-label="Choose slide"></select>
  <button id="next" aria-label="Next slide">→</button>
  <label><input id="instructor" type="checkbox"> Instructor slides</label>
  <button id="notesToggle" aria-pressed="false">Speaker notes</button>
  <button id="present">Present</button>
  <button id="print">Print / PDF</button>
</header>
<main id="stage" aria-label="Slide"><div id="canvas"></div></main>
<div id="notes" hidden></div>
<footer><span id="count" aria-live="polite"></span> · Arrow keys to navigate · Home / End · N for notes · F for fullscreen · Esc to leave fullscreen</footer>
<script id="slideData" type="application/json">__SLIDES__</script>
<script>
const data = JSON.parse(document.getElementById('slideData').textContent);
const canvas = document.getElementById('canvas');
const picker = document.getElementById('picker');
const notes = document.getElementById('notes');
const hiddenIds = new Set(['status', 'open-decisions']);
let visible = [], current = 0;
for (const item of data) {
  const template = document.createElement('template');
  template.innerHTML = item.html.trim();
  item.node = template.content.firstElementChild;
  if (!item.node || item.node.tagName !== 'SECTION') throw new Error('Invalid slide: ' + item.id);
  item.title = item.node.querySelector('h1, h2')?.textContent.trim() || item.id;
  canvas.appendChild(item.node);
}
function filterSlides() {
  const previous = visible[current]?.id;
  const include = document.getElementById('instructor').checked;
  visible = data.filter(item => include || !hiddenIds.has(item.id));
  for (const item of data) item.node.classList.toggle('excluded', !visible.includes(item));
  picker.replaceChildren();
  visible.forEach((item, i) => {
    const option = document.createElement('option');
    option.value = i;
    option.textContent = `${i + 1}. ${item.title}${hiddenIds.has(item.id) ? ' [instructor]' : ''}`;
    picker.appendChild(option);
  });
  const retained = visible.findIndex(item => item.id === previous);
  show(retained < 0 ? Math.min(current, visible.length - 1) : retained);
}
function show(index) {
  current = Math.max(0, Math.min(index, visible.length - 1));
  for (const item of data) item.node.classList.remove('active');
  const item = visible[current];
  item.node.classList.add('active');
  picker.value = current;
  notes.textContent = item.node.querySelector('aside')?.textContent.trim() || 'No speaker notes.';
  document.getElementById('count').textContent = `Slide ${current + 1} of ${visible.length}${hiddenIds.has(item.id) ? ' · Instructor only' : ''}`;
  document.getElementById('prev').disabled = current === 0;
  document.getElementById('next').disabled = current === visible.length - 1;
  fit();
}
function fit() {
  const stage = document.getElementById('stage');
  const scale = Math.min(stage.clientWidth / 1920, stage.clientHeight / 1080);
  canvas.style.transform = `scale(${scale})`;
  canvas.style.left = `${(stage.clientWidth - 1920 * scale) / 2}px`;
  canvas.style.top = `${(stage.clientHeight - 1080 * scale) / 2}px`;
}
function toggleNotes() {
  notes.hidden = !notes.hidden;
  document.getElementById('notesToggle').setAttribute('aria-pressed', String(!notes.hidden));
  fit();
}
async function present() {
  try {
    if (document.fullscreenElement) await document.exitFullscreen();
    else await document.documentElement.requestFullscreen();
  } catch (error) { alert('Fullscreen is unavailable. You can maximise the browser window.'); }
}
document.getElementById('prev').onclick = () => show(current - 1);
document.getElementById('next').onclick = () => show(current + 1);
picker.onchange = () => show(Number(picker.value));
document.getElementById('instructor').onchange = filterSlides;
document.getElementById('notesToggle').onclick = toggleNotes;
document.getElementById('present').onclick = present;
document.getElementById('print').onclick = () => window.print();
document.addEventListener('fullscreenchange', () => {
  document.body.classList.toggle('presenting', Boolean(document.fullscreenElement));
  fit();
});
document.addEventListener('keydown', event => {
  if (event.target.matches('input, select, button, textarea, summary')) return;
  if (['ArrowRight', 'ArrowDown', 'PageDown', ' '].includes(event.key)) { event.preventDefault(); show(current + 1); }
  if (['ArrowLeft', 'ArrowUp', 'PageUp'].includes(event.key)) { event.preventDefault(); show(current - 1); }
  if (event.key === 'Home') { event.preventDefault(); show(0); }
  if (event.key === 'End') { event.preventDefault(); show(visible.length - 1); }
  if (event.key.toLowerCase() === 'n') toggleNotes();
  if (event.key.toLowerCase() === 'f') present();
});
new ResizeObserver(fit).observe(document.getElementById('stage'));
canvas.querySelectorAll('a[href^="http"]').forEach(a => { a.target = '_blank'; a.rel = 'noopener'; });
filterSlides();
</script>
<script id="topicData" type="application/json">__TOPICS__</script>
<script>
/* Topic draw: turns slide "p1-draw" into the live draw. The list is remembered in this browser (localStorage).
   The draw is seeded (the seed is shown), so the same list + seed always gives the same result. */
(() => {
  const item = data.find(i => i.id === 'p1-draw');
  if (!item) return;
  const topics = JSON.parse(document.getElementById('topicData').textContent).sort((a, b) => a.id - b.id);
  const KEY = 'aiw-topic-draw-v1';
  let S = { people: [], draw: null };
  try { const saved = JSON.parse(localStorage.getItem(KEY) || 'null'); if (saved && Array.isArray(saved.people)) S = saved; } catch (e) {}
  const save = () => { try { localStorage.setItem(KEY, JSON.stringify(S)); } catch (e) {} };

  const sec = item.node;
  const notesAside = sec.querySelector('aside');
  sec.removeAttribute('style');
  sec.classList.add('drawapp');
  sec.innerHTML = `
    <div class="da-head">
      <div><p class="da-eyebrow">PART 1 · TOPIC DRAW</p><h2 class="da-title">Who works on what</h2></div>
      <div class="da-stats"><div><b id="daPool">0</b><span>in the pool</span></div><div><b id="daOwn">0</b><span>own topic</span></div><div><b id="daTopicN">0</b><span>topics</span></div></div>
      <div class="da-actions"><button id="daDraw" class="da-btn da-primary" type="button">Draw lots</button><button id="daReplay" class="da-btn" type="button">Replay reveal</button><button id="daReset" class="da-btn" type="button">Reset draw</button></div>
    </div>
    <p class="da-note" id="daNote"></p>
    <div class="da-body">
      <div class="da-pane">
        <form id="daForm" autocomplete="off">
          <input id="daName" maxlength="80" placeholder="Name, or group (e.g. Ana + Ben)" aria-label="Name or group">
          <div class="da-choice" role="group" aria-label="Topic choice"><button type="button" data-c="pool" class="on" aria-pressed="true">Pool</button><button type="button" data-c="own" aria-pressed="false">Own topic</button></div>
          <input id="daOwnTopic" maxlength="160" placeholder="Their own topic" aria-label="Own topic" hidden>
          <button class="da-btn" type="submit">Add</button>
        </form>
        <details><summary>Paste a list of names</summary><textarea id="daPaste" aria-label="Names, one per line" placeholder="One name or group per line. All go into the pool."></textarea><button id="daPasteBtn" class="da-btn" type="button">Add all to the pool</button></details>
        <ul class="da-list" id="daPeople"></ul>
      </div>
      <div class="da-pane">
        <h3 class="da-h3">Topic pool <span class="da-seed" id="daSeed"></span></h3>
        <ol class="da-topics" id="daTopics"></ol>
        <div class="da-actions"><button id="daCsv" class="da-btn" type="button">Save assignments.csv</button><button id="daCopy" class="da-btn" type="button">Copy as text</button></div>
      </div>
    </div>
    <div class="da-stage" id="daStage" hidden>
      <p class="da-count" id="daCount"></p>
      <p class="da-name" id="daStageName"></p>
      <div class="da-slip" id="daSlip"><span class="no" id="daSlipNo"></span><span class="t" id="daSlipT"></span></div>
      <div class="da-actions"><button id="daNext" class="da-btn da-primary" type="button">Next</button><button id="daClose" class="da-btn" type="button">Close</button></div>
      <p class="da-hint">Space or → for the next draw · Esc to close</p>
    </div>`;
  if (notesAside) sec.appendChild(notesAside);
  const $ = id => sec.querySelector('#' + id);
  const node = (tag, cls, text) => { const n = document.createElement(tag); if (cls) n.className = cls; if (text != null) n.textContent = text; return n; };

  function mulberry32(a) { return function () { a |= 0; a = (a + 0x6D2B79F5) | 0; let t = Math.imul(a ^ (a >>> 15), 1 | a); t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t; return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; }
  function shuffle(arr, rnd) { const a = arr.slice(); for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(rnd() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; } return a; }
  const pool = () => S.people.filter(p => p.choice === 'pool');
  function computeDraw(seed) {
    const rnd = mulberry32(seed);
    const order = shuffle(pool(), rnd);
    const picks = shuffle(topics, rnd).slice(0, order.length);
    return order.map((p, i) => ({ pid: p.id, name: p.name, topicId: picks[i].id, title: picks[i].title, keywords: picks[i].keywords || '' }));
  }
  function armed(btn, label, action) {
    if (btn.dataset.armed) { delete btn.dataset.armed; btn.classList.remove('da-armed'); action(); return; }
    const old = btn.textContent; btn.dataset.armed = '1'; btn.classList.add('da-armed'); btn.textContent = label;
    setTimeout(() => { if (btn.dataset.armed) { delete btn.dataset.armed; btn.classList.remove('da-armed'); btn.textContent = old; } }, 3000);
  }

  function render() {
    const p = pool(), own = S.people.filter(x => x.choice === 'own'), drawn = !!S.draw;
    const got = new Map((S.draw ? S.draw.assignments : []).map(a => [a.pid, a]));
    $('daPool').textContent = p.length; $('daOwn').textContent = own.length; $('daTopicN').textContent = topics.length;
    const tooMany = p.length > topics.length;
    $('daDraw').hidden = drawn; $('daDraw').disabled = !p.length || tooMany;
    $('daReplay').hidden = !drawn; $('daReset').hidden = !drawn;
    $('daSeed').textContent = drawn ? '· seed ' + S.draw.seed : '';
    const late = drawn && p.some(x => !got.has(x.id));
    $('daNote').textContent = !topics.length ? 'No topics found: check instructor/topics/topic_pool.csv and run build_preview.py again.'
      : drawn ? (late ? 'Some pool entries were added after the draw. Reset the draw to include them.' : 'Done. Students: copy your topic into 1_topic/my_topic.md, then run the research-question skill.')
      : tooMany ? p.length + ' in the pool but only ' + topics.length + ' topics: add topics to topic_pool.csv or move people to Own topic.'
      : p.length ? p.length + ' pool entries will each get a different topic. Press Draw lots.'
      : 'Add every student or group, as Pool or Own topic. Then press Draw lots.';

    const ul = $('daPeople'); ul.replaceChildren();
    if (!S.people.length) ul.appendChild(node('li', 'da-empty', 'Nobody yet. Type a name above and press Add.'));
    for (const x of S.people) {
      const li = node('li');
      li.appendChild(node('span', 'da-chip ' + x.choice, x.choice === 'own' ? 'OWN' : 'POOL'));
      const who = node('span', 'da-who'); who.appendChild(node('b', null, x.name));
      const a = got.get(x.id);
      if (x.choice === 'own') who.appendChild(node('small', 'got', x.ownTopic || 'own topic (not given)'));
      else if (a) who.appendChild(node('small', 'got', '#' + a.topicId + '  ' + a.title));
      li.appendChild(who);
      const rm = node('button', 'da-x', 'Remove'); rm.type = 'button'; rm.setAttribute('aria-label', 'Remove ' + x.name);
      rm.onclick = () => armed(rm, 'Sure?', () => { S.people = S.people.filter(y => y.id !== x.id); save(); render(); });
      li.appendChild(rm); ul.appendChild(li);
    }
    const taken = new Set((S.draw ? S.draw.assignments : []).map(a => a.topicId));
    const ol = $('daTopics'); ol.replaceChildren();
    for (const t of topics) { const li = node('li', taken.has(t.id) ? 'taken' : null); li.appendChild(node('span', null, String(t.id).padStart(2, '0'))); li.appendChild(document.createTextNode(t.title)); ol.appendChild(li); }
  }

  function rows() {
    const got = new Map((S.draw ? S.draw.assignments : []).map(a => [a.pid, a]));
    return S.people.map(x => { const a = got.get(x.id); return x.choice === 'own' ? [x.name, 'own', 'own', x.ownTopic || '', ''] : [x.name, 'pool', a ? a.topicId : '', a ? a.title : '', a ? a.keywords : '']; });
  }
  const cell = v => { const s = String(v ?? ''); return /[",\n;]/.test(s) ? '"' + s.replace(/"/g, '""') + '"' : s; };

  let choice = 'pool';
  sec.querySelectorAll('.da-choice button').forEach(b => b.onclick = () => {
    choice = b.dataset.c;
    sec.querySelectorAll('.da-choice button').forEach(o => { o.classList.toggle('on', o === b); o.setAttribute('aria-pressed', String(o === b)); });
    $('daOwnTopic').hidden = choice !== 'own';
  });
  $('daForm').onsubmit = e => {
    e.preventDefault();
    const name = $('daName').value.trim(); if (!name) return;
    S.people.push({ id: Date.now().toString(36) + Math.random().toString(36).slice(2, 6), name, choice, ownTopic: choice === 'own' ? $('daOwnTopic').value.trim() : '' });
    $('daName').value = ''; $('daOwnTopic').value = ''; sec.querySelector('.da-choice button[data-c="pool"]').click(); save(); render(); $('daName').focus();
  };
  $('daPasteBtn').onclick = () => {
    const names = $('daPaste').value.split(/\r?\n/).map(s => s.trim()).filter(Boolean);
    names.forEach((name, i) => S.people.push({ id: Date.now().toString(36) + i + Math.random().toString(36).slice(2, 6), name, choice: 'pool', ownTopic: '' }));
    $('daPaste').value = ''; sec.querySelector('details').open = false; save(); render();
  };
  $('daDraw').onclick = () => {
    const seed = crypto.getRandomValues(new Uint32Array(1))[0] % 1000000;
    S.draw = { seed, drawnAt: Date.now(), assignments: computeDraw(seed) }; save(); render(); openStage();
  };
  $('daReplay').onclick = openStage;
  $('daReset').onclick = () => armed($('daReset'), 'Click again to reset', () => { S.draw = null; save(); render(); });
  $('daCsv').onclick = () => {
    const text = [['name', 'choice', 'topic_id', 'topic', 'keywords'], ...rows()].map(r => r.map(cell).join(',')).join('\n') + '\n';
    const a = document.createElement('a'); a.href = URL.createObjectURL(new Blob(['﻿' + text], { type: 'text/csv' })); a.download = 'assignments.csv';
    document.body.appendChild(a); a.click(); setTimeout(() => { URL.revokeObjectURL(a.href); a.remove(); }, 1000);
  };
  $('daCopy').onclick = async () => {
    const text = rows().map(r => r[0] + ': ' + (r[1] === 'own' ? r[3] + ' (own topic)' : r[2] ? '#' + r[2] + ' ' + r[3] : 'no topic yet')).join('\n');
    try { await navigator.clipboard.writeText(text); $('daCopy').textContent = 'Copied'; } catch (e) { $('daCopy').textContent = 'Copy blocked'; }
    setTimeout(() => ($('daCopy').textContent = 'Copy as text'), 2000);
  };

  // reveal
  const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  let R = { i: -1, busy: false };
  function openStage() { if (!S.draw || !S.draw.assignments.length) return; R = { i: -1, busy: false }; $('daStage').hidden = false; next(); }
  function closeStage() { $('daStage').hidden = true; }
  function next() {
    const list = S.draw.assignments;
    if (R.busy) return;
    if (R.i >= list.length - 1) { closeStage(); return; }
    const a = list[++R.i];
    $('daCount').textContent = (R.i + 1) + ' / ' + list.length + '   ·   seed ' + S.draw.seed;
    $('daStageName').textContent = a.name;
    $('daNext').textContent = R.i === list.length - 1 ? 'Show the list' : 'Next';
    const land = () => { $('daSlip').classList.remove('spinning'); $('daSlipNo').textContent = '#' + String(a.topicId).padStart(2, '0'); $('daSlipT').textContent = a.title; R.busy = false; };
    if (reduce || topics.length < 2) return land();
    R.busy = true; $('daSlip').classList.add('spinning'); let n = 0;
    const tick = () => { const t = topics[Math.floor(Math.random() * topics.length)]; $('daSlipNo').textContent = '#' + String(t.id).padStart(2, '0'); $('daSlipT').textContent = t.title; if (++n < 14) setTimeout(tick, 60 + n * 8); else land(); };
    tick();
  }
  $('daNext').onclick = next;
  $('daClose').onclick = closeStage;
  // While the reveal is open, Space / → / Enter / Esc drive the draw instead of changing slides.
  window.addEventListener('keydown', e => {
    if ($('daStage').hidden || !sec.classList.contains('active')) return;
    if ([' ', 'ArrowRight', 'Enter', 'Escape'].includes(e.key)) {
      e.preventDefault(); e.stopImmediatePropagation();
      if (e.key === 'Escape') closeStage(); else next();
    }
  }, true);
  render();
})();
</script>
</body>
</html>'''


if __name__ == "__main__":
    build()
