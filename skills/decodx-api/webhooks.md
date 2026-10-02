# decodx webhooks

A workspace admin adds the endpoint in the web app (Integrations → Add webhook), picks the events
and copies the signing secret, which is shown once and starts with `ddx_whsec_`. The same page
sends a test `ping`, lists deliveries and replays them.

## What arrives

`POST` to your URL with a JSON body:

```json
{ "id": "…", "type": "video.ready", "version": 1, "occurredAt": "2026-10-02T10:00:00Z", "data": { … } }
```

| `type` | `data` |
|---|---|
| `video.ready` | `{ ref, title, url }` — `ref` is the project id; `url` is a path such as `/videos/{id}` |
| `job.failed` | `{ ref, message }` |
| `share.viewed` | `{ sharedPageId }` |
| `comment.created` | `{ itemId }` or `{ sharedPageId }` |
| `ping` | test delivery |

Headers: `X-Decodx-Signature`, `X-Decodx-Timestamp` (unix seconds), `X-Decodx-Event`,
`X-Decodx-Delivery` (unique per delivery).

## Verify every delivery

The signature is `v1=` plus the hex HMAC-SHA256 of `"<timestamp>.<raw body>"`, keyed with the
whole secret string (prefix included). Verify against the **raw** body bytes, before any JSON
parsing, compare in constant time, and reject timestamps more than 5 minutes old.

```ts
import { createHmac, timingSafeEqual } from 'node:crypto';

export function verifyDecodxWebhook(
  secret: string,
  rawBody: string,
  signature: string | null,
  timestamp: string | null,
): boolean {
  if (!signature || !timestamp) return false;
  const ts = Number(timestamp);
  if (!Number.isFinite(ts) || Math.abs(Date.now() / 1000 - ts) > 300) return false;
  const expected = `v1=${createHmac('sha256', secret).update(`${timestamp}.${rawBody}`).digest('hex')}`;
  const a = Buffer.from(expected);
  const b = Buffer.from(signature);
  return a.length === b.length && timingSafeEqual(a, b);
}
```

Return `401` when it fails.

## Respond fast, process once

- Any `2xx` counts as delivered. Anything else is retried after about 1 min, 5 min, 30 min, 2 h and
  6 h, then given up. Return `2xx` quickly and do slow work in a queue.
- A delivery can arrive more than once (retries, manual replays). Deduplicate on
  `X-Decodx-Delivery` (or the body `id`).
- For `video.ready`, fetch the video with `GET /videos/{id}` for a fresh `downloadUrl`; don't
  trust any URL beyond the ids in the payload.
