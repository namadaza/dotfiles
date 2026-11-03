---
name: vercel-pr-slack
description: Copy a GitHub pull request to the macOS clipboard as a Slack-ready snippet with a linked PR title and inline-code diff counts. Use when asked to copy, format, or share a PR for Slack.
---

# Copy a PR for Slack

Create a clipboard snippet with this shape:

```text
:pr: <linked PR title> +1,150 -135
```

Only the title is linked to the PR. The added and deleted line counts are
separate inline-code spans. The script writes Slack's native rich-text clipboard
format as well as HTML, RTF, and plain-text fallbacks; do not replace it with
`pbcopy`, Slack API markup, or a separate URL line.

## Requirements

- Run locally on macOS, where the user will paste into Slack.
- Bun (`bun`) and an authenticated GitHub CLI (`gh`).
- macOS's built-in `textutil` and `osascript` commands.

## Workflow

1. Use the GitHub PR URL supplied by the user or already established in the
   conversation. If there is no unambiguous PR URL, ask for one. Do not create a
   new PR or change an existing one.
2. Resolve `scripts/vercel-pr-slack.ts` relative to this skill directory (the
   directory containing this `SKILL.md`), not the current working directory.
3. Run the bundled script, quoting both the absolute script path and the URL:

   ```sh
   bun "<absolute-skill-directory>/scripts/vercel-pr-slack.ts" "https://github.com/vercel/gtm/pull/5535"
   ```

   This fetches the current title and diff counts from GitHub and replaces the
   local clipboard contents. It does not post to Slack.
4. Check the exit status. On success, briefly confirm the snippet was copied and
   tell the user to paste normally into Slack. Do not claim success on a failed
   command; report the error and any missing prerequisite instead.

The terminal's plain-text output does not display the title's hyperlink; that
formatting lives in the clipboard data. Plain-text-only paste will discard it.
