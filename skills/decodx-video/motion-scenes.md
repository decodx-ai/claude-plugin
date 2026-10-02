# Motion scenes

You write the visual of a motion scene as an HTML fragment (`<style>` + markup + `<script>`) with
GSAP. decodx records the narration first, measures every word, and gives your code the exact time
of each named moment — so the chart grows as the number is said and the diagram builds as each step
is named. The frames are identical on every render.

## What to make a motion scene

| Narration has… | Show it as |
|---|---|
| A number or metric ("grew forty-two percent") | A counter that rolls up, a bar or line that grows, a big figure that lands on the word |
| A process or flow ("upload, review, publish") | Boxes and arrows that appear one by one as each step is named |
| A structure ("the API talks to three services") | An architecture diagram that builds part by part |
| A comparison ("before… now…") | A split screen or a wipe from the old state to the new one |
| A sequence over time ("in March… by June…") | A timeline with a marker that moves along it |
| A list of points | Each point reveals and ticks on the word that introduces it |
| A UI idea or feature | A simplified mock of the screen with the key element highlighted |
| The opening hook | Kinetic text: the key words animate in as they are spoken |

Only real product footage, the opening title, chapter breaks, the closing call to action, and an
on-screen presenter are better as other scene kinds.

## Step by step

1. **Write the narration for the scene first.** The animation is built around it. Write numbers as
   words ("forty-two", not "42") — that is what the voice says and what a cue matches.
2. **Pick 2–5 cues — one per visual beat.** A cue names a moment by a word or phrase that is
   actually spoken:

   ```json
   { "bars": { "word": "revenue" }, "count": { "word": "forty-two" }, "markets": { "phrase": "three new markets" } }
   ```

   Optional per cue: `occurrence` (the nth time the text is said), `edge` (`start` or `end` of the
   word), `offset` (seconds, default -0.1, so the visual lands just before the word).
3. **`add_motion_scene`** with the narration and cues (plus `hold`, up to 3 s of extra time after
   the last word, if the last beat needs to breathe).
4. **`time_motion_scene`.** It records the voice and returns the scene length, `decodx.safeEnd`,
   `decodx.end`, every cue's time and every word's time, plus the full authoring rules. Read them.
   It uses a little voice quota, so re-run it only after changing the narration, cues, hold or
   voice (`update_motion_scene`).
5. **`set_motion_animation`** with your HTML. It checks that the animation fits the scene, every cue
   is used and lands on its word, and frames are identical across renders. It returns findings and
   a frame at each cue.
6. **Look at the frames**, fix, and call `set_motion_animation` again until there are no ✗ findings.
   Expect two or three rounds. Then `preview_scene` shows it like any other scene.

## The rules the runtime enforces

- One timeline: `const tl = gsap.timeline({ paused: true });` … `decodx.register(tl);`. GSAP is the
  only animation library.
- Time every narration-linked motion with `decodx.cue('name')`, never with seconds you computed.
- Key content must be visible before `decodx.safeEnd`; everything finishes by `decodx.end`.
- No `Date.now`, `setTimeout`, `setInterval`, `requestAnimationFrame` loops, CSS transitions or CSS
  animations — decodx owns the clock. `Math.random` is seeded, so it is safe.
- The canvas is `decodx.width` × `decodx.height` design units: always 1920 wide, height from the
  aspect ratio (1080 for 16:9). Lay out in those units; decodx scales to the output size.
- The bottom ~20% is the caption band. Keep important content out of it.
- Brand: `decodx.brand.font`, `decodx.brand.accent` and `decodx.brand.background` (null when the
  workspace has none — choose a background yourself).
- Draw with inline SVG and CSS rather than loading external files.

## Example

Narration: "Revenue grew forty-two percent across three new markets." Cues as in step 2.

```html
<style>
  #stage { position: absolute; inset: 0; background: linear-gradient(135deg, #1b1f3a, #2b2350);
           color: #fff; font-family: system-ui, sans-serif; }
  #title { position: absolute; left: 115px; top: 120px; font-size: 64px; font-weight: 700; }
  .bar { position: absolute; bottom: 330px; width: 88px; border-radius: 16px 16px 0 0;
         background: rgba(255,255,255,.28); transform-origin: bottom; }
  #pct { position: absolute; left: 1110px; top: 300px; font-size: 210px; font-weight: 900; }
  #markets { position: absolute; left: 1110px; top: 560px; font-size: 40px; letter-spacing: .08em; }
</style>
<div id="stage">
  <div id="title">Q3 revenue</div>
  <div class="bar" style="left:115px;height:170px"></div>
  <div class="bar" style="left:245px;height:200px"></div>
  <div class="bar" style="left:375px;height:185px"></div>
  <div class="bar" style="left:505px;height:235px"></div>
  <div class="bar" style="left:635px;height:260px"></div>
  <div class="bar hot" style="left:765px;height:370px"></div>
  <div id="pct">+0%</div>
  <div id="markets">3 NEW MARKETS</div>
</div>
<script>
  const brand = decodx.brand;
  const stage = document.getElementById('stage');
  stage.style.fontFamily = `'${brand.font}', system-ui, sans-serif`;
  if (brand.background) stage.style.background = brand.background;
  document.querySelector('.bar.hot').style.background = brand.accent;

  const tl = gsap.timeline({ paused: true });
  tl.from('#title', { opacity: 0, y: 20, duration: 0.5 }, 0);
  tl.from('.bar', { scaleY: 0, stagger: 0.1, duration: 0.6, ease: 'power2.out' }, decodx.cue('bars'));
  const n = { v: 0 };
  tl.to(n, {
    v: 42, duration: 0.8, ease: 'power1.out',
    onUpdate: () => { document.getElementById('pct').textContent = `+${Math.round(n.v)}%`; },
  }, decodx.cue('count'));
  tl.from('#pct', { opacity: 0, scale: 0.8, duration: 0.4, ease: 'back.out' }, decodx.cue('count'));
  tl.from('#markets', { opacity: 0, y: 30, duration: 0.4 }, decodx.cue('markets'));
  decodx.register(tl);
</script>
```

## Check the frames before you call it done

- Each cue's frame shows the thing the voice is saying at that moment.
- Nothing is cut off at the edges or hidden behind the caption band.
- Text is large enough to read on a phone: headlines at least 56 units, labels at least 28.
- One idea per scene. If the frame at the last cue is crowded, split the scene in two.
- The colours and font match the brand (`get_brand_guardrails` for tone and words).
