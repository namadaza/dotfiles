---
name: pr-creator
description:
  Use this skill when asked to create a pull request (PR) from a prepared branch.
  It infers a conventional title, follows the template, and returns a compact PR link.
---

# Pull Request Creator

This skill creates GitHub Pull Requests from an already-prepared local branch
that has been pushed to GitHub, using a concise conventional title and a compact
final response.

## Workflow

Follow these steps to create a Pull Request:

1.  **Branch Management**: **CRITICAL:** Ensure you are NOT working on the
    `main` branch.
    - Run `git branch --show-current`.
    - If the current branch is `main`, you MUST create and switch to a new
      descriptive branch:
      ```bash
      git checkout -b <new-branch-name>
      ```

2.  **Committed and Pushed Changes**: Verify that all intended changes are
    committed and that the branch is pushed to GitHub.
    - Run `git status` to check for unstaged or uncommitted changes.
    - If there are uncommitted changes, stop and ask the user whether to commit
      them before creating the PR. Do not assume the changes should be included.
    - Confirm the branch has an upstream with `git status -sb` or push it with
      `git push -u origin HEAD` if the user has asked you to do so. NEVER push
      if the current branch is `main`.

3.  **Infer PR Title**: Create a title in this format:

    ```text
    type(scope): short description
    ```

    - Use `feat` for new behavior and `fix` for bug fixes. Infer the type from
      the branch name, commits, and diff. If ambiguous, ask the user.
    - Infer `scope` from the app or project named in the branch. Branches often
      look like `amanazad/auto-outbound-fix-instructions-for-agent` or
      `amanazad/gtm-workflows-add-update-api`; the scopes are `auto-outbound`
      and `gtm-workflows`.
    - Keep the description short, imperative, and specific.
    - Example titles:
      ```text
      feat(auto-outbound): add update API
      fix(gtm-workflows): fix instructions for agent
      ```

4.  **Locate Template**: Search for a pull request template in the repository.
    - Check `.github/pull_request_template.md`
    - Check `.github/PULL_REQUEST_TEMPLATE.md`
    - If multiple templates exist (e.g., in `.github/PULL_REQUEST_TEMPLATE/`),
      ask the user which one to use or select the most appropriate one based on
      the context (e.g., `bug_fix.md` vs `feature.md`).

5.  **Read Template**: Read the content of the identified template file.

6.  **Draft Description**: Create a PR description that strictly follows the
    template's structure.
    - **Headings**: Keep all headings from the template.
    - **Checklists**: Review each item. Mark with `[x]` if completed. If an item
      is not applicable, leave it unchecked or mark as `[ ]` (depending on the
      template's instructions) or remove it if the template allows flexibility
      (but prefer keeping it unchecked for transparency).
    - **Content**: Fill in the sections with clear, concise summaries of your
      changes.
    - **Related Issues**: Link any issues fixed or related to this PR (e.g.,
      "Fixes #123").

7.  **Preflight Check**: Before creating the PR, run the workspace preflight
    script to ensure all build, lint, and test checks pass.
    ```bash
    npm run preflight
    ```
    If any checks fail, address the issues before proceeding to create the PR.

8.  **Create PR**: Use the `gh` CLI to create the PR. To avoid shell escaping
    issues with multi-line Markdown, write the description to a temporary file
    first.
    ```bash
    # 1. Write the drafted description to a temporary file
    # 2. Create the PR using the --body-file flag
    gh pr create --title "type(scope): short description" --body-file <temp_file_path>
    # 3. Remove the temporary file
    rm <temp_file_path>
    ```

9.  **Final Response**: After creating the PR, respond with only one compact
    line in this exact shape:

    ```markdown
    :pr: [feat(auto-outbound): update endpoints to support AO campaign CRUD via eve agent](https://github.com/vercel/gtm/pull/1654) `+423` `-32`
    ```

    - Put the final PR title in the link text.
    - Put the PR URL in the link target.
    - Include the total added and deleted lines from the PR diff as separate
      inline code strings.
    - Prefer `gh pr view --json additions,deletions,title,url` to get the final
      title, URL, added lines, and deleted lines.
    - If needed before the PR exists, use `git diff --shortstat <base>...HEAD`
      to estimate the added and deleted lines.

## Principles

- **Safety First**: NEVER push to `main`. This is your highest priority.
- **Compliance**: Never ignore the PR template. It exists for a reason.
- **Completeness**: Fill out all relevant sections.
- **Accuracy**: Don't check boxes for tasks you haven't done.
