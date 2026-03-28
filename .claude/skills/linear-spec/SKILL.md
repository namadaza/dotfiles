---
name: linear-spec
description: Refine a Linear ticket into an implementation-ready spec by researching the codebase.
---

# Linear Spec

Takes a Linear ticket title or identifier, researches the codebase, and writes a detailed implementation spec back into the issue description.

## Usage

```
/linear-spec <ticket title or identifier>
```

Examples:
- `/linear-spec lead scoring improvements`
- `/linear-spec ENG-123`

## Prerequisites

- `LINEAR_API_KEY` must be set in the environment. If it is not, stop with a clear message telling the user to set it.

## Workflow

### 1. Find the ticket

Parse the user's argument:

- If it matches an identifier pattern (`[A-Z]+-\d+`): run `bun ~/.claude/skills/linear-spec/linear.ts get-by-identifier <identifier>` to fetch directly.
- Otherwise: run `bun ~/.claude/skills/linear-spec/linear.ts search "<title>"` to fuzzy-match (scoped to `night-shift` label).
- If multiple matches, pick the best match or list them and ask the user.
- If no matches, tell the user and stop.

### 2. Read current state

- Run `bun ~/.claude/skills/linear-spec/linear.ts get <issue-id>` to fetch the full issue.
- Read the existing description — this contains the user's initial requirements/notes. Save this content; it will be preserved in the final spec.
- Check parent/child issues for additional context.

### 3. Research the codebase

Based on the ticket's requirements, explore the codebase:

- Find files that will need to change.
- Trace relevant code paths.
- Identify existing patterns, utilities, and conventions to reuse.
- Check for related tests.
- Understand the data model / schema if relevant.
- Load `~/.claude/skills/night-shift/code-preferences.md` for coding conventions (shared with night-shift).

**Important: This skill is read-only on the codebase. Do not modify any code files.**

### 4. Write the refined spec

Produce a structured spec in markdown. The spec should be formatted so night-shift can pick it up directly:

```markdown
## Original Requirements

<original description content from the ticket, preserved verbatim>

---

## Summary

What this change does and why.

## Affected Files

List of files to create/modify with brief descriptions of changes.

## Implementation Approach

Step-by-step plan with specifics: function names, schema changes, component hierarchy, service layer methods.

## Edge Cases & Considerations

Error handling, migrations, backwards compatibility.

## Testing Strategy

Integration tests first (per night-shift testing conventions), what to assert, fixtures needed.

## Acceptance Criteria

Clear pass/fail conditions night-shift can validate against.
```

Follow conventions from `~/.claude/skills/night-shift/code-preferences.md` when naming functions, choosing patterns, etc.

### 5. Update the ticket

- Write the spec description to a temp file and pass it via stdin to avoid shell escaping issues:

```bash
cat /tmp/linear-spec-desc.md | xargs -0 -I {} bun ~/.claude/skills/linear-spec/linear.ts update <issue-id> {}
```

Or write it inline if short enough. The `update` command takes the issue ID and description as arguments.

- Confirm to the user with the issue identifier and URL.

## Guardrails

- **Read-only on the codebase** — this skill researches but does not modify code.
- **Preserve user intent** — the original description content must be retained under the "Original Requirements" section.
- **No state changes** — do not change the issue's status, assignee, labels, or any other field besides the description. The user manages the ticket lifecycle.
- **No commits** — this skill does not create branches, commits, or PRs.

## Shared CLI

The `linear.ts` CLI in this directory is shared with the `night-shift` skill (which uses `list-todo`, `transition`, `list-states`, `get`, and `comment` commands). Changes to the CLI interface should be coordinated across both skills.
