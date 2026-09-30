---
name: decodx-video
description: >-
  Make narrated product videos, explainers, tutorials and deck-to-video with the decodx MCP server
  (tools like create_project, add_scenes, validate_project, preview_scene, render_project). Use when
  the user wants to create, edit or render a video with decodx; follow the validate → preview →
  render loop so every render succeeds first time.
license: Proprietary — for use with the decodx service
---

# Make videos with decodx

decodx turns a list of scenes into a finished MP4 with captions, chapters and a thumbnail. The same
scenes always render the same video. You drive it through the decodx MCP server
(`https://api.decodx.ai/mcp`), which this plugin connects.

## The loop that renders first time

1. **Start a project.** `create_project`, or `create_with_prompt` for a first draft from a brief.
2. **Read the rules before writing.** `get_brand_guardrails` (tone, words to use or avoid).
   Valid ids come from the server, never guess them:
   - slide layouts and their fields: `list_slide_templates`
   - presenters: `list_avatars`
   - voices: listed in `set_voice`'s description
   The same catalogs are MCP resources (`decodx://catalog/...`).
3. **Build scenes.** `add_scenes` / `update_scenes`. Every write replies with a validation digest —
   fix what it lists as you go.
4. **Motion scenes** (animated charts, diagrams): `add_motion_scene` → `time_motion_scene` (records
   the voice, returns word timings) → `set_motion_animation` until it reports ✓.
5. **Look before you render.** `preview_scene` returns frames of a slide, title, terminal or motion
   scene plus any layout problem (overflowing or clipped text) — the same audit the render runs.
6. **Validate.** `validate_project` returns every issue at once, each with a fix and a rule id.
   Fix them all and validate again until it is clean.
7. **Check cost.** `estimate_duration` gives the length and the AI minutes a render will use.
8. **Render.** `render_project` returns a job id; poll `get_job` at the interval it suggests.

`render_project` runs the same checks as `validate_project` and refuses with the full list, so a
job that would fail validation never starts.

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
