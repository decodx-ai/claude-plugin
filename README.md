# decodx

[decodx](https://decodx.ai) makes narrated videos from a list of scenes. A scene can be a slide, a screen recording, an animated chart or a talking presenter. Each video has captions, chapters and a thumbnail. The same scenes always give the same video.

This plugin connects Claude Code to the decodx remote MCP server (`https://api.decodx.ai/mcp`). It also adds the `decodx-video` skill. The skill tells Claude the correct procedure to make a video that renders at the first attempt.

## What you can do

- Make a product demonstration video from a short description.
- Make an explainer video from your notes or a document.
- Change a slide deck (PDF or PowerPoint) into a narrated video.
- Change a screen recording into a tutorial with zoom and highlights.
- Edit a video scene by scene, and render it again.
- Share a video with a link.

## Quick start

1. Add the marketplace:

   ```bash
   claude plugin marketplace add decodx-ai/claude-plugin
   ```

2. Install the plugin:

   ```bash
   claude plugin install decodx@decodx
   ```

3. Start Claude Code, then type `/mcp`.
4. Select `decodx`, then sign in to decodx in your browser.
5. Make sure that `decodx` shows as **connected**.
6. Tell Claude what video you want:

   > Make a 60-second product demo video for my app.

If you do not have a decodx account, you can make one when you sign in.

## Example usage

Tell Claude Code to:

- "Make a 60-second product demo video for Acme SSO."
- "Change my slide deck into a narrated video with a friendly tone."
- "Make a short explainer video from the notes in `docs/pricing.md`."
- "Show me the frames of the second scene before you render."
- "Check my project for problems, then render it."

## How it works

Claude uses this procedure for each video:

1. Claude makes a project and adds the scenes.
2. Claude reads your brand rules and uses only valid templates, voices and presenters.
3. Claude shows you frames of the scenes. The frames show text that does not fit on the screen.
4. Claude checks the full project. The check finds all problems before the render starts.
5. Claude tells you the length of the video and the cost in AI minutes.
6. Claude renders the video and gives you the link.

A render starts only when the project has no problems. Thus, a render does not fail because of a problem that a check can find.

## Available tools

The MCP server has more than 60 tools. These are the most important tools:

| Tool | What it does |
|---|---|
| `create_project` | Makes a new video project. |
| `create_with_prompt` | Makes a first draft of a project from a short description. |
| `add_scenes`, `update_scenes` | Adds scenes to a project, or changes them. |
| `import_deck` | Adds the slides of a PDF or PowerPoint deck as scenes. |
| `ingest_recording` | Adds a screen recording as scenes. |
| `add_motion_scene` | Adds an animated scene, for example a chart. |
| `preview_scene` | Shows frames of a scene and each problem in its layout. |
| `validate_project` | Checks the full project and shows all problems with their fixes. |
| `estimate_duration` | Shows the length of the video and the cost in AI minutes. |
| `render_project` | Renders the video. |
| `get_job` | Shows the status of a render. |
| `create_share` | Makes a link to share a video. |

## Resources and prompts

The server also gives these resources. Claude can read them without a tool call:

- `decodx://guide/authoring`: the procedure and the list of all checks.
- `decodx://catalog/slide-templates`, `decodx://catalog/voices`, `decodx://catalog/avatars`: the valid templates, voices and presenters.
- `decodx://projects/{project_id}/composition`: the scenes of one project.

The server also gives four prompts. Select them from the prompt menu:

- **Product demo video**
- **Turn a slide deck into a video**
- **Explainer from notes**
- **Recording to tutorial**

## Details

### Sign-in

The server uses OAuth. You sign in to decodx in your browser. Claude does not see your password. You can remove the access of Claude at any time in the decodx app.

### Safe retries

Each tool that makes a change accepts an `idempotency_key`. If a call does not complete, Claude can send it again with the same key. decodx does not apply the change two times.

Each change also accepts an `expected_version`. If another person changes the project first, decodx stops the call. Thus, Claude does not write over the change of another person.

### Cost

A render uses AI minutes from your decodx plan. Use `estimate_duration` to see the cost before the render. A render of scenes that did not change is free.

## Connect without the plugin

You can connect only the MCP server, without the skill:

```bash
claude mcp add --transport http decodx https://api.decodx.ai/mcp
```

To connect Claude on the web or in the desktop app, do these steps:

1. Open **Settings**, then open **Connectors**.
2. Select **Add custom connector**.
3. Type `https://api.decodx.ai/mcp`, then select **Connect**.

## Problems and solutions

- **`decodx` does not show as connected.** Type `/mcp`, select `decodx` and sign in again.
- **Claude says that a project has problems.** This is correct. Each problem has a fix. Tell Claude to apply the fixes and check the project again.
- **A scene cannot show frames.** Only slide, title, terminal and motion scenes can show frames before the render. The check still finds problems in the other scenes.

## Plugin contents

```
claude-plugin/
├── .claude-plugin/
│   ├── plugin.json            # Plugin metadata
│   └── marketplace.json       # Marketplace metadata
├── .github/workflows/
│   └── release.yml            # Makes a release from a version
├── .mcp.json                  # Connection to the decodx MCP server
├── scripts/
│   └── normalize-version.sh   # Changes 0.0.1 to v0.0.1
└── skills/
    └── decodx-video/
        └── SKILL.md           # The procedure to make a video
```

## Release a new version

Only maintainers do this procedure.

1. On GitHub, open **Actions**.
2. Select the **Release** workflow.
3. Select **Run workflow**.
4. Type the version, for example `0.0.1` or `v0.0.1`. Both give the tag `v0.0.1`.
5. Select **Run workflow** again.

The workflow checks the version and the plugin files. Then it sets the version in `plugin.json`, makes the tag and makes the GitHub release. A version with a hyphen, for example `1.0.0-beta.1`, becomes a pre-release.

Users get the new version with this command:

```bash
claude plugin marketplace update decodx
```

## Documentation

- [MCP server](https://decodx.ai/docs/automate/mcp-server)
- [Quick start](https://decodx.ai/docs/get-started/quickstart)
- [Errors and limits](https://decodx.ai/docs/reference/errors-and-limits)

---

Maintained by [decodx](https://decodx.ai). Support: support@decodx.ai
