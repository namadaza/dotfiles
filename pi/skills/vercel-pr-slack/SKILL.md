---
name: vercel-pr-slack
description: Copy a GitHub pull request to the macOS clipboard as Markdown for Slack, with a linked PR title and inline-code diff counts. Use when asked to copy, format, or share a PR for Slack.
---

# Copy a PR for Slack

Create a clipboard snippet using standard Markdown:

```markdown
:pr: [PR title](https://github.com/vercel/gtm/pull/5535) `+1,150` `-135`
```

Only the title is linked to the PR. The added and deleted line counts are
separate inline-code spans. Escape Markdown characters in the title so they
remain literal. Use Markdown links (`[title](url)`), not Slack API markup
(`<url|title>`), custom rich-text clipboard formats, HTML, or RTF.

## Requirements

- Run locally on macOS, where the user will paste into Slack.
- Bun (`bun`) and an authenticated GitHub CLI (`gh`).
- macOS's built-in `pbcopy` command.
- Slack's Markdown composer enabled for Markdown formatting.

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

   This fetches the current title and diff counts from GitHub and copies the
   Markdown text with `pbcopy`. It prints the same Markdown in the terminal.
   It does not post to Slack.
4. Check the exit status. On success, briefly confirm the Markdown snippet was
   copied and tell the user to paste into Slack's Markdown composer. If Slack
   shows the raw syntax instead of formatting, check that its Markdown composer
   is enabled; do not switch back to rich clipboard formats.
5. Do not claim success on a failed command. If clipboard copying fails, the
   script prints an error and the generated Markdown for manual copying. Show
   that message to the user. If fetching the PR fails, report the error instead
   of inventing a title or diff counts.
