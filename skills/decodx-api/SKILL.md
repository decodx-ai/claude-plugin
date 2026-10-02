---
name: decodx-api
description: >-
  Integrate the decodx REST API into code: create and edit video projects, render them as jobs,
  collect the MP4, captions and chapters, share or embed the result, and receive webhooks. Use when
  writing a service, script or CI job that makes decodx videos over HTTP (for example a release
  video on every tag), or embedding decodx videos in an app. For making one video interactively,
  use the decodx MCP server and the decodx-video skill instead.
license: Proprietary — for use with the decodx service
---

# Build on the decodx REST API

Base URL: `https://api.decodx.ai`. Every body is JSON and schema-validated. There is no official
SDK — call it over plain HTTP. For the exact fields of any endpoint, read it from the OpenAPI
document (`https://decodx.ai/openapi.public.json`, large: extract one path with `jq`, see the
decodx-docs skill).

## Authenticate

Send `Authorization: Bearer <token>` on every request. Tokens start with `ddx_svc_`.

- **A service, script or CI job:** the user creates a service token in the web app
  (Settings → Advanced), picks its scopes and copies it once. Read it from an environment variable
  or a secret store (for example `DECODX_API_TOKEN`). Never hard-code, print or commit it.
- **A tool a person signs in to:** use the OAuth device flow (`POST /oauth/device_authorization`,
  then poll `POST /oauth/token` with `grant_type=urn:ietf:params:oauth:grant-type:device_code`).
  A device-flow token counts as an AI assistant, so its renders can be held for approval (below).

Scopes are `resource:action`, for example `video:write`, `share:write`. A call outside the
token's scopes returns `403` naming the missing scope. `GET /me` shows who the token is and its
organization.

## The render loop

A render is a job, not a request that returns a video.

```bash
API=https://api.decodx.ai
AUTH="Authorization: Bearer $DECODX_API_TOKEN"
JSON='content-type: application/json'

# 1. Create a project — blank, or a first draft from a brief (never renders)
PID=$(curl -sf -X POST $API/projects/from-prompt -H "$AUTH" -H "$JSON" \
  -d '{"prompt":"60-second tour of our new billing page","tone":"friendly"}' | jq -r .id)

# 2. Read the composition, edit it, write it back (full replace)
curl -sf $API/projects/$PID/composition -H "$AUTH" > comp.json      # {composition, updatedAt}
# ...edit comp.json .composition.scenes...
jq '{composition, baseUpdatedAt: .updatedAt}' comp.json |
  curl -sf -X PUT $API/projects/$PID/composition -H "$AUTH" -H "$JSON" -d @-

# 3. Estimate length and cost
curl -sf $API/projects/$PID/compose/estimate -H "$AUTH"   # durationSeconds, aiMinutes, reusedRenderFree

# 4. Render
curl -s -X POST $API/projects/$PID/compose -H "$AUTH" -H "$JSON" \
  -d "{\"idempotencyKey\":\"release-$GIT_SHA\"}"
```

Step 4 returns `202` with one of two bodies:

- `{ jobId, estimate, reused? }` — the job started. `reused: true` means an identical earlier
  render was reused at no cost; pass `"force": true` to render again anyway.
- `{ status: "awaiting_approval", approvalId, reviewUrl, estimate }` — a person must approve it
  first (assistant tokens only; no job yet, no charge). Show the user `reviewUrl`, then poll
  `GET /render-requests/{approvalId}` until `status` is `approved` (it then carries `jobId`),
  or stop on `rejected`, `expired` or `superseded`. Requests expire after 48 hours.

A composition that cannot render returns `422` before any job starts, with `issues[]` — each has
`sceneId`, `field`, `message` and usually `fix`. Fix them all and call `compose` again.

### Poll the job and collect the video

`GET /jobs/{jobId}` → `status`: `queued`, `dispatching`, `running`, then `succeeded`, `failed` or
`canceled`, plus `progress` (0–100) and `stage`. Poll every few seconds, or stream
`GET /jobs/{jobId}/events` (Server-Sent Events). On `failed`, `error.code`, `error.message` and
`error.stage` say what to fix. `POST /jobs/{jobId}/cancel` stops a job.

When it succeeds, `artifacts[]` lists each output (`video`, `captions`, `chapters`, `thumbnail`,
`transcript`, `doc`) with an `itemId` and `url`. `GET /videos/{itemId}` for the video gives
`downloadUrl`, `thumbnailUrl`, `durationSeconds` and `chapters`. Download URLs expire — fetch a
fresh one instead of storing it. Other sizes: `POST /videos/{id}/export`
(`resolution`: `480p`, `720p`, `1080p` or `4k`), then poll `GET /exports/{exportId}`.

## Edit the composition, don't write it from scratch

The composition is `{ version: 1, globals, scenes[] }`. Scenes have a `kind` (`video`, `image`,
`title`, `generated`, `gradient`, `avatar`, `cli`, `slide`, `motion`), an `id`, `narration` and
`narrationMode` (`auto` or `manual`). Start from a `from-prompt` draft or an existing project and
change what you need, so every required field is already right. Valid voices and presenters:
`GET /brand/catalog/voices`, `GET /brand/catalog/avatars`.

Pass the `updatedAt` you read as `baseUpdatedAt` on the `PUT`. A `409` means someone else changed
the project after you read it: read it again, re-apply your change and retry.

To use your own recording or image: `POST /uploads {contentType}` → `{uploadUrl, key}`, `PUT` the
bytes to `uploadUrl`, then `POST /assets {uploadKey, kind: "video"|"image", filename}` → an asset
id to reference from a scene. Uploads are limited to 2 GB.

## Share and embed

`POST /shared {itemId, itemType: "video", visibility: "unlisted"}` → `{id, slug}`. Visibility is
`public`, `unlisted` (default) or `private`; `settings` controls comments, downloads and expiry.
The share page is `https://app.decodx.ai/public/{slug}`. To put the video on a site, read
[embed.md](embed.md).

## Webhooks

Instead of polling, a workspace admin adds a webhook in the web app's Integrations page (events
`video.ready`, `job.failed`, `share.viewed`, `comment.created`). To write the receiver, read
[webhooks.md](webhooks.md) — every delivery must be signature-checked.

## Errors and retries

Errors are `{ code, message, fix? }` — read `fix` and change the request. Common statuses:

| Status | Meaning | Do |
|---|---|---|
| 401 | Token missing, wrong or revoked | Get a new token |
| 402 | Out of AI minutes | Tell the user; do not retry |
| 403 | Missing scope | Use a token with the named scope |
| 409 | Stale `baseUpdatedAt` | Re-read, re-apply, retry |
| 413 | Body over 10 MB | Upload media through `/uploads` instead |
| 422 | Composition cannot render | Apply each issue's `fix` |
| 429 | Rate limited | Wait for `Retry-After`, then retry |

Retry only `429` and `5xx`, with backoff. A retried `compose` with the same `idempotencyKey`
returns the job it already started instead of rendering twice — always send one from automation.
Lists page with `?limit=` (up to 100) and `?cursor=`, following `nextCursor`.
