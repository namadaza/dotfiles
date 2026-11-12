import { afterEach, expect, test } from "bun:test";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";

const directories: string[] = [];
afterEach(async () => {
  await Promise.all(directories.splice(0).map((dir) => rm(dir, { recursive: true })));
});

async function run({
  behavior = "success",
  title = "Test PR",
  url = "https://github.com/vercel/gtm/pull/5742",
}: {
  behavior?: "success" | "clipboard-error" | "gh-error";
  title?: string;
  url?: string | null;
} = {}) {
  const dir = await mkdtemp(join(tmpdir(), "vercel-pr-slack-test-"));
  directories.push(dir);
  const executable = (name: string, body: string) =>
    writeFile(join(dir, name), `#!/bin/sh\n${body}\n`, { mode: 0o755 });
  await Promise.all([
    executable("gh", `
printf '%s\\n' "$@" > "$TEST_DIR/gh-args"
if [ "$TEST_BEHAVIOR" = "gh-error" ]; then
  echo "GitHub authentication failed" >&2
  exit 1
fi
printf '%s' "$TEST_PR"`),
    executable("pbcopy", `
/bin/cat > "$TEST_DIR/clipboard"
if [ "$TEST_BEHAVIOR" = "clipboard-error" ]; then
  echo "Clipboard unavailable" >&2
  exit 1
fi`),
  ]);
  const child = Bun.spawn([
    process.execPath,
    join(import.meta.dir, "vercel-pr-slack.ts"),
    ...(url === null ? [] : [url]),
  ], {
    env: {
      ...process.env,
      PATH: `${dir}:${process.env.PATH}`,
      TEST_DIR: dir,
      TEST_BEHAVIOR: behavior,
      TEST_PR: JSON.stringify({ title, additions: 1150, deletions: 135 }),
    },
    stdout: "pipe",
    stderr: "pipe",
  });
  const [stdout, stderr, exitCode] = await Promise.all([
    new Response(child.stdout).text(),
    new Response(child.stderr).text(),
    child.exited,
  ]);
  return { stdout, stderr, exitCode, dir };
}

const expected = ":pr: [Test PR](https://github.com/vercel/gtm/pull/5742) `+1,150` `-135`";

test("copies standard Markdown with a linked title and separate inline-code counts", async () => {
  const result = await run();
  expect(result.exitCode).toBe(0);
  expect(result.stderr).toBe("");
  expect(result.stdout).toContain(expected);
  expect(result.stdout).toContain("Copied Markdown to clipboard");
  expect(await readFile(join(result.dir, "clipboard"), "utf8")).toBe(expected);
  expect(await readFile(join(result.dir, "gh-args"), "utf8")).toBe(
    "api\nrepos/vercel/gtm/pulls/5742\n",
  );
});

test("escapes Markdown in titles without interpreting shell characters", async () => {
  const result = await run({ title: "PR's [fix] *bold* _text_ `code` <tag> \\ $(echo unexpected)\nnext" });
  expect(result.exitCode).toBe(0);
  expect(await readFile(join(result.dir, "clipboard"), "utf8")).toBe(
    ":pr: [PR's \\[fix\\] \\*bold\\* \\_text\\_ \\`code\\` \\<tag\\> \\\\ $(echo unexpected) next](https://github.com/vercel/gtm/pull/5742) `+1,150` `-135`",
  );
});

test("normalizes trailing slashes, queries, and fragments out of the Markdown link", async () => {
  const result = await run({ url: "https://github.com/vercel/gtm/pull/5742/?test=(value)#discussion" });
  expect(result.exitCode).toBe(0);
  expect(await readFile(join(result.dir, "clipboard"), "utf8")).toBe(expected);
});

test("reports clipboard failure and retains the Markdown for manual copying", async () => {
  const result = await run({ behavior: "clipboard-error" });
  expect(result.exitCode).toBe(1);
  expect(result.stderr).toContain("Clipboard unavailable");
  expect(result.stderr).toContain("Copy the Markdown message printed above manually");
  expect(result.stdout.trim()).toBe(expected);
  expect(result.stdout).not.toContain("Copied Markdown");
});

test("does not copy or claim success when GitHub fails", async () => {
  const result = await run({ behavior: "gh-error" });
  expect(result.exitCode).toBe(1);
  expect(result.stderr).toContain("GitHub authentication failed");
  expect(result.stdout).toBe("");
  expect(await Bun.file(join(result.dir, "clipboard")).exists()).toBe(false);
});

for (const url of [null, "https://example.com/vercel/gtm/pull/5742"]) {
  test(`rejects ${url === null ? "missing" : "invalid"} PR URLs before fetching or copying`, async () => {
    const result = await run({ url });
    expect(result.exitCode).toBe(1);
    expect(result.stderr).toContain(url === null ? "Usage:" : "Invalid GitHub PR URL");
    expect(result.stdout).toBe("");
    expect(await Bun.file(join(result.dir, "gh-args")).exists()).toBe(false);
    expect(await Bun.file(join(result.dir, "clipboard")).exists()).toBe(false);
  });
}
