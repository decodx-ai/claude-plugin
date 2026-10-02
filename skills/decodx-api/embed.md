# Embed a decodx video

Embedding needs a share: `POST /shared` → `{ slug }`. A `private` share does not play for
anonymous viewers; use `unlisted` or `public` for a site.

## iframe

```html
<iframe
  src="https://embed.decodx.ai/v1/SLUG"
  title="Product tour"
  style="width:100%;aspect-ratio:16/9;border:0"
  allow="autoplay; fullscreen"
  allowfullscreen
></iframe>
```

Query parameters:

| Parameter | Effect |
|---|---|
| `mode=video` | Plain video player (default is `interactive`, which follows the project's click-through steps) |
| `autoplay=0` | Do not start automatically |
| `frame=browser` | Draw a browser frame around the video |
| `show_copy_link=1` | Show a copy-link button |
| `password=…` | Unlock a password-protected share |
| `utm_*` | Passed through to analytics |

## Script tag

```html
<div data-decodx-slug="SLUG" data-frame="browser" data-show-copy-link="1"></div>
<script src="https://embed.decodx.ai/player.js" defer></script>
```

## Player events

The player posts messages to the host page:

```js
window.addEventListener('message', (e) => {
  if (e.origin !== 'https://embed.decodx.ai' || e.data?.source !== 'decodx-player') return;
  // e.data.event: step_change, cta_click, complete, sound_on, replayed, copy_link, fullscreen
});
```

With the script tag, the same events are also dispatched on the `div` as `decodx:<event>`
custom events (for example `decodx:complete`).

## Other ways to show it

- oEmbed (for CMSs that support it):
  `GET https://api.decodx.ai/public/oembed?url=https://app.decodx.ai/public/SLUG`
- A stable MP4 or thumbnail link (redirects to a fresh file each time) for an unlisted or public
  share: `https://api.decodx.ai/public/SLUG/media.mp4`,
  `https://api.decodx.ai/public/SLUG/thumbnail`
