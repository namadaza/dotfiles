#!/usr/bin/env bun

const prUrl = process.argv[2];

if (!prUrl) {
  console.error(`Usage: bun ${process.argv[1]} <GitHub PR URL>`);
  process.exit(1);
}

const match = prUrl.match(
  /^https:\/\/github\.com\/([^/]+)\/([^/]+)\/pull\/(\d+)\/?(?:[?#].*)?$/,
);

if (!match) {
  console.error(`Invalid GitHub PR URL: ${prUrl}`);
  process.exit(1);
}

const [, owner, repo, pullNumber] = match;
const gh = Bun.spawn(
  ["gh", "api", `repos/${owner}/${repo}/pulls/${pullNumber}`],
  {
    stdout: "pipe",
    stderr: "pipe",
  },
);

const [response, error, exitCode] = await Promise.all([
  new Response(gh.stdout).text(),
  new Response(gh.stderr).text(),
  gh.exited,
]);

if (exitCode !== 0) {
  console.error(error.trim() || "Failed to fetch PR details with GitHub CLI.");
  process.exit(exitCode);
}

const { title, additions, deletions } = JSON.parse(response) as {
  title: string;
  additions: number;
  deletions: number;
};

const formatNumber = (value: number) => value.toLocaleString("en-US");
const additionsText = `+${formatNumber(additions)}`;
const deletionsText = `-${formatNumber(deletions)}`;
// Keep titles literal, even when they contain Markdown or line breaks.
const escapeMarkdown = (value: string) =>
  value.replace(/[\r\n]+/g, " ").replace(/[\\`*_[\]<>]/g, "\\$&");
const canonicalUrl = `https://github.com/${owner}/${repo}/pull/${pullNumber}`;
const slackMessage = `:pr: [${escapeMarkdown(title)}](${canonicalUrl}) \`${additionsText}\` \`${deletionsText}\``;

// Plain Markdown is intentional: Slack can parse it without custom clipboard
// formats, HTML conversion, or AppleScript. Pass text on stdin, never via a shell.
console.log(slackMessage);
try {
  const clipboard = Bun.spawn(["pbcopy"], {
    stdin: "pipe",
    stderr: "pipe",
  });
  clipboard.stdin.write(slackMessage);
  clipboard.stdin.end();

  const [clipboardError, clipboardExitCode] = await Promise.all([
    new Response(clipboard.stderr).text(),
    clipboard.exited,
  ]);
  if (clipboardExitCode !== 0) {
    console.error(
      `Failed to copy the Markdown message to the clipboard (exit ${clipboardExitCode}).` +
        (clipboardError.trim() ? `\n${clipboardError.trim()}` : "") +
        "\nCopy the Markdown message printed above manually.",
    );
    process.exit(clipboardExitCode);
  }
} catch (error) {
  console.error(
    `Failed to copy the Markdown message to the clipboard: ${error}\n` +
      "Copy the Markdown message printed above manually.",
  );
  process.exit(1);
}

console.log("Copied Markdown to clipboard. Paste into Slack's Markdown composer.");
