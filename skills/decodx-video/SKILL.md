---
name: decodx-video
description: >-
  Make narrated product videos, explainers, tutorials and deck-to-video with the decodx MCP server,
  building scenes as motion scenes (animated charts, diagrams, flows and kinetic text you write as
  HTML/GSAP, synced to the voice) by default. Use when the user wants to create, edit or render a
  video with decodx; follow the validate → preview → render loop so every render succeeds first
  time.
license: Proprietary — for use with the decodx service
---

# Make videos with decodx

decodx turns a list of scenes into a finished MP4 with captions, chapters and a thumbnail. The same
scenes always render the same video. You drive it through the decodx MCP server
(`https://api.decodx.ai/mcp`), which this plugin connects.

## Motion scenes first

A motion scene is decodx's most powerful scene: you design the visual yourself in HTML, CSS, SVG and
GSAP, and decodx times every beat to the exact word the voice says. Anything a browser can draw, a
motion scene can show — a chart that grows as the number is spoken, a diagram that builds step by
step, a before/after wipe, a timeline, a mock of the UI idea. Templates can't do that.

**Make every scene a motion scene unless another kind is clearly better:**

| Use instead | Only when |
|---|---|
| Recording or uploaded video | The scene must show the real product on screen |
| Slide (`title`, `section`, `cta`) | An opening title, a chapter break or the closing call to action |
| Avatar | The user asked for a presenter on screen |

If a scene's narration has a number, a sequence, a comparison, a process or a structure, it is a
motion scene. Even a scene you would make a bullet list is better as motion: reveal each point on
the word that introduces it. Read [motion-scenes.md](motion-scenes.md) before writing the first one —
it has the patterns, the cue rules and a complete example.

## The loop that renders first time

1. **Start a project.** `create_project`, or `create_with_prompt` for a first draft from a brief.
2. **Read the rules before writing.** `get_brand_guardrails` (tone, words to use or avoid).
   Valid ids come from the server, never guess them:
   - slide layouts and their fields: `list_slide_templates`
   - presenters: `list_avatars`
   - voices: listed in `set_voice`'s description
   The same catalogs are MCP resources (`decodx://catalog/...`).
3. **Plan the scenes, motion first.** Write the narration scene by scene, and for each one decide
   its kind using the table above — motion unless there is a reason not to.
4. **Build motion scenes:** `add_motion_scene` (narration + cues) → `time_motion_scene` (records
   the voice, returns the exact time of every word and cue) → `set_motion_animation` (your HTML;
   returns findings and a frame at each cue) — look at the frames, fix, and call again until it
   reports ✓. Build the other scenes with `add_scenes` / `update_scenes`. Every write replies with a
   validation digest — fix what it lists as you go.
5. **Look before you render.** `preview_scene` returns frames of a slide, title, terminal or motion
   scene plus any layout problem (overflowing or clipped text) — the same audit the render runs.
6. **Validate.** `validate_project` returns every issue at once, each with a fix and a rule id.
   Fix them all and validate again until it is clean.
7. **Check cost.** `estimate_duration` gives the length and the AI minutes a render will use.
8. **Render.** `render_project` returns a job id; poll `get_job` at the interval it suggests.

`render_project` runs the same checks as `validate_project` and refuses with the full list, so a
job that would fail validation never starts.

Rendering spends the workspace's AI minutes, so a person approves it first unless their workspace
allows assistant renders. Then `render_project` returns `awaiting_approval: true` with a
`review_url` and no job: give the user that link, then poll `get_render_request` with the
`approval_id` — once approved it carries the job id for `get_job`. You cannot approve a render
yourself. A re-render of an unchanged project is free and never waits.

## Writing good scenes

- One idea per scene. Short slide text — text that does not fit is refused before render.
- Narration is spoken; write it the way a person talks. Keep it within the scene: with the project
  fit set to `auto`, video clips slow down to match the voice.
- Effects (zoom, highlight, blur, arrow, spotlight) use regions as fractions of the frame:
  `[x, y, width, height]`, all between 0 and 1.

## Safe retries

Every write accepts an optional `idempotency_key` — retry a timed-out call with the same key and it
is not applied twice. Pass the project `version` (from `get_project` or your last write) as
`expected_version` so you never overwrite someone else's edit; on a conflict, re-read and re-apply.

## When something fails

Errors say what is wrong and how to fix it. Read the fix, change the call, retry. A failed job
(`get_job`) lists the stage and the fix; correct the project, `validate_project`, then render again.
