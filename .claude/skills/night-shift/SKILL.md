---
name: night-shift
description: Agentic development loop (plan, test, code) to work on tasks from file specs or Linear issues.
---

# Night Shift

Autonomous development loop for implementing features and fixes from spec files or Linear issues. Designed to run unattended against one or more specs.

## Mode Selection

**Linear mode** is activated by passing ticket IDs as arguments: `/night-shift GTM-233 GTM-539 GTM-555`. The tickets are worked in the order given.

**File mode** is the default when no ticket IDs are provided: `/night-shift`. Uses local spec files from `.claude/specs/`.

## Picking Up Work

### File Mode (default — no arguments)

Look in `.claude/specs/` for specs prefixed with `todo-`. A spec can be either:

- **A file**: `todo-2026-03-14-new-feature.md` -- for simple changes.
- **A folder**: `todo-2026-03-14-new-feature/README.md` -- for larger specs with supporting files. The `README.md` is the main spec; other files in the folder are supplementary context.

Pick one spec at a time. When a spec is complete, rename it to drop the `todo-` prefix (e.g., `todo-2026-03-14-feature.md` → `2026-03-14-feature.md`, or `todo-2026-03-14-feature/` → `2026-03-14-feature/`). Then check for the next `todo-` spec and repeat.

The `.claude/` directory is gitignored, so specs persist across branch switches and don't need to be committed to any branch. (This concern does not apply to Linear mode.)

If no `todo-` specs remain, stop.

### Linear Mode (ticket IDs as arguments)

Work through the ticket IDs in the order they were provided. For each ticket:

1. Fetch the full spec: `bun ~/.claude/skills/linear-spec/linear.ts get <issue-id>`. The issue description is the spec content.
2. Transition to In Progress: `bun ~/.claude/skills/linear-spec/linear.ts transition <issue-id> started`.

When all provided tickets have been completed, stop.

## Branching Strategy

Work happens on **feature branches in the current repo checkout** -- not worktrees, not clones. The repo is already set up with the correct environment variables (`.env.local`, etc.) and has `pnpm install` already run. Do not create worktrees or re-clone the repo.

For each spec:
1. Create a feature branch from the current HEAD: `amanazad/<short-description>`
2. Do all work on that branch.
3. Push the feature branch and open a PR.
4. After the PR is created, check out `main` (or the original branch) before picking up the next spec.

## Guardrails

- **Never push directly to the git repo's main branch.** All work happens on feature branches. Push to the feature branch only.
- **Scope guard.** Only change what the spec requires. Do not refactor unrelated code, add unrelated features, or "improve" things outside the spec's scope. If you notice something unrelated that needs attention, note it in the spec file being worked on — don't fix it.
- **Abort after 3 failed review cycles.** If the review personas raise blocking concerns 3 times and the plan/implementation still can't pass, stop. In file mode, document the blocker in the spec file. In Linear mode, add a comment documenting the blocker (`bun ~/.claude/skills/linear-spec/linear.ts comment <issue-id> "<blocker details>"`) and leave the ticket in `started` (In Progress). Then move on to the next spec (or stop if none remain).
- **Restart services if they go down.** If a dev server or worker becomes unresponsive, restart it before continuing.

## Discovering Commands

Do not assume which commands are available. Instead, discover them:

1. **Root `package.json`** -- Read the root `package.json` for monorepo-wide scripts (build, lint, typecheck, format, etc.).
2. **App-level `package.json`** -- For app-specific commands (dev server, tests, migrations, evals), find the relevant app under `apps/` and read its `package.json`.
3. **Turborepo filter** -- In a turborepo monorepo, use `pnpm --filter <app-name>` to run app-specific scripts from the root.
4. **Cache what you find** -- Once you've identified the commands for a spec, you don't need to re-read package.json files for the same app.

## Loop

### 1. Prep

- Run `git status`. If the repo has uncommitted changes, review them, run tests, fix issues, and commit before starting.
- **File mode:** Check `.claude/specs/` for the next `todo-` prefixed spec file.
- **Linear mode:** Take the next ticket ID from the provided list. Fetch the full spec with `bun ~/.claude/skills/linear-spec/linear.ts get <issue-id>`. Transition to in progress: `bun ~/.claude/skills/linear-spec/linear.ts transition <issue-id> started`.
- Create a feature branch per the branching strategy above. Branch name should be descriptive but concise (e.g., `amanazad/lead-scoring-fix`, `amanazad/add-export-endpoint`).
- **File mode:** Log the branch name in the spec file at the top.
- **Linear mode:** Log the branch name as a comment: `bun ~/.claude/skills/linear-spec/linear.ts comment <issue-id> "Branch: amanazad/<name>"`.

### 2. Understand

- Read the spec file thoroughly.
- Load relevant docs from this skills folder `./claude/skills/night-shift` (especially `code-preferences.md`, `testing.md`).
- Read the existing code that will be affected. Understand before changing.

### 3. Test Plan

- Develop an extensive testing plan, primarily integration tests.
- Any dev servers or background services needed for the spec should be running. Find the relevant app's `package.json` to identify the dev command (typically `pnpm --filter <app-name> dev`). Start them if they're not already up.
- If a service crashes during the loop, restart it before continuing.

### 4. Write Failing Tests

- Write the tests first. Run them and confirm they fail (TDD).
- Rely primarily on unit and integration tests.

### 5. Plan

- Develop an implementation plan for the feature or fix.
- The plan should be specific: name the files to create/modify, the services to add, the schema changes, the components to build.

### 6. Review the Plan

- Review the plan through each persona in `./claude/skills/night-shift/personas.md`.
- Each persona outputs: **approve**, **suggest** (non-blocking), or **concern** (blocking).
- If any persona raises a concern, revise the plan and re-review.
- Once all personas approve or suggest, finalize the plan.

### 7. Implement

- Implement the plan. Only change what the spec requires.
- Update documentation if the spec changes public behavior, API contracts, or developer-facing patterns.
- **Commit incrementally.** Don't save all commits for the end. Commit after each meaningful chunk of progress (e.g., tests written, service layer done, UI wired up). Use concise, descriptive messages so the PR history tells a clear story.

### 8. Validate

Run all available validation commands and fix issues as they come up. Check the root and app-level `package.json` for the relevant scripts. Typical checks include:

- Type checking
- Linting
- Building
- Tests (unit, integration, e2e -- whatever is available and relevant to the spec)

Iterate until all checks pass. If a check fails, fix the issue and re-run.

### 8b. Browser Validation (UI specs only)

**Required for any spec that adds or changes UI pages/components.** Skip only for backend-only specs with zero UI changes.

1. Make sure the app's dev server is running (e.g., `pnpm --filter <app-name> dev`). Start it if it isn't.
2. Use `npx agent-browser open <url>` to open each new or changed page.
3. Walk through the primary user flows described in the spec (submit a form, expand a card, click filters, etc.).
4. If something is broken or visually wrong, fix it and re-run validation (step 8) before continuing.

See `testing.md` section 3 for details.

### 9. Review the Implementation

- Run the review personas again, this time against the actual implementation diff (not the plan).
- If any persona raises a blocking concern, fix it, re-run validation (step 8), and re-review.
- **If this fails 3 times, abort.** Log the blocker in the spec file and move on.

### 10. Wrap Up

- Commit any remaining uncommitted changes.
- **Rebase off the base branch** before pushing: `git fetch origin && git rebase origin/main` (or `origin/dev`, whichever is the repo's default branch). If there are conflicts, resolve them, then continue the rebase. Re-run validation (step 8) after rebasing to make sure nothing broke.
- Push the feature branch and create a **draft** PR with a summary statement (`gh pr create --draft`). Format for title should be `feat(app-name): short description`, or `fix(app-name): short description`
- **Add screenshots for UI specs.** If the spec added or changed UI, capture screenshots and include them in the PR. See the "PR Screenshots" section below.
- **File mode:**
  - Add an entry in spec file summarizing: what was done, the branch name, and the PR URL. Prefix the entry with today's date, e.g., `## 3-16-2026 Updates`.
  - Rename the spec file to drop the `todo-` prefix (e.g., `.claude/specs/todo-2026-03-14-feature.md` → `.claude/specs/2026-03-14-feature.md`). Note the branch name at the top of the spec file.
  - Check `.claude/specs/` for the next `todo-` spec. If one exists, go back to step 1. If not, stop.
- **Linear mode:**
  - Add a comment summarizing what was done, the branch name, and the PR URL: `bun ~/.claude/skills/linear-spec/linear.ts comment <issue-id> "<summary, branch, PR URL>"`.
  - Do **not** transition the ticket to Done — leave it in `started` (In Progress). The team moves it to Done after reviewing the PR.
  - If there are more ticket IDs remaining in the provided list, go back to step 1. If all tickets have been completed, stop.

## PR Screenshots

**Required for any spec that adds or changes UI.** Skip for backend-only specs.

### Capturing screenshots

Use agent-browser during step 8b to capture clean (non-annotated) screenshots of each new or changed page into `/tmp/`:

```bash
npx agent-browser open http://localhost:3000/path-to-page
npx agent-browser wait 2000
npx agent-browser screenshot --full /tmp/page-name.png
```

For pages that require interaction to reach a specific state (e.g., authenticated views, filled forms), use `fill`/`click`/`eval` commands to set up the state before taking the screenshot.

### Uploading screenshots to Vercel Blob

Use the upload script in this skill's directory to push screenshots to Vercel Blob. The script requires `BLOB_READ_WRITE_TOKEN` to be set in the environment (it should already be present on this machine).

```bash
bun ~/.claude/skills/night-shift/upload-screenshots.ts /tmp/page-name.png /tmp/other-page.png
```

The script outputs one line per file in the format `<local_path> -> <blob_url>`. Save the blob URLs for the PR body.

After uploading, remove the local temp files:
```bash
rm /tmp/page-name.png /tmp/other-page.png
```

### Adding screenshots to the PR

Update the PR body to include a `## Screenshots` section with the Vercel Blob URLs. **Use `gh api` with `--field body=@file`** because `gh pr edit` fails on repos with deprecated Projects Classic:

```bash
# Write the full PR body to a file (markdown, not JSON)
cat <<'BODY' > /tmp/pr-body.md
## Summary
...

## Screenshots

### Page Name
![Page Name](<blob-url-from-upload-script>)

## Test plan
...
BODY

# PATCH via REST API -- reads file contents as the body field
gh api repos/<org>/<repo>/pulls/<number> -X PATCH -F "body=@/tmp/pr-body.md"
```

Use the exact blob URLs returned by the upload script. No commit or push is needed for screenshots -- they are hosted externally on Vercel Blob.
