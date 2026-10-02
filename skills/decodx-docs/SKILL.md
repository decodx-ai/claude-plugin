---
name: decodx-docs
description: >-
  Look up current decodx documentation and API reference before answering or writing code. Use
  when you need a decodx fact you are not sure of: plans and AI minutes, limits and error codes,
  share links and embeds, voices and avatars, the REST API, or the MCP server. Fetches the docs as
  Markdown instead of relying on memory.
license: Proprietary — for use with the decodx service
---

# Look up the decodx docs

The decodx docs change as the product ships. Read the current page instead of guessing, and quote
what it says.

## Find the page

`https://decodx.ai/llms.txt` is the index: one line per docs page, with its Markdown URL and a
one-line summary. Fetch it first and pick the page whose summary matches the question.

Every docs page has a Markdown twin. Add `.md` to its URL:

```
https://decodx.ai/docs/automate/rest-api.md
https://decodx.ai/docs/reference/errors-and-limits.md
https://decodx.ai/docs/share-and-measure/embed-and-export.md
```

When the question spans several pages, or you cannot tell which page holds the answer,
`https://decodx.ai/llms-full.txt` has every page inlined in one file (about 40 KB). Search it
rather than reading all of it.

## Look up an endpoint

The full API contract is the OpenAPI document at `https://decodx.ai/openapi.public.json`. It is
large (over 1.5 MB), so never read it whole — pull out the one path you need:

```bash
curl -s https://decodx.ai/openapi.public.json -o /tmp/decodx-openapi.json
jq -r '.paths | keys[]' /tmp/decodx-openapi.json                  # every path
jq '.paths["/jobs"].post' /tmp/decodx-openapi.json                 # one operation
```

The API base URL is `https://api.decodx.ai`. Ignore the `servers` entry in the file.

## Workflow

1. Fetch `llms.txt` and choose the page (or search `llms-full.txt`).
2. Fetch that page with the `.md` suffix.
3. For an endpoint's exact request and response fields, read that path from the OpenAPI file.
4. Answer or write the code from what the page says, and link the page (without `.md`) for the
   user.

If the docs do not cover the question, say so and point the user to `https://decodx.ai/docs/help`
or support@decodx.ai — do not invent an answer.
