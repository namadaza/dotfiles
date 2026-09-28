#!/usr/bin/env bun

const prUrl = process.argv[2];

if (!prUrl) {
  console.error("Usage: bun scripts/vercel-pr-slack.ts <GitHub PR URL>");
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
const slackMessage = `:pr: ${title} \`${additionsText}\` \`${deletionsText}\``;

// Slack's <url|label> syntax is for messages sent through its API and is not
// parsed when pasted into the composer. Copy RTF instead so macOS puts a real
// hyperlink and rich inline-code styling on the clipboard.
const escapeHtml = (value: string) =>
  value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
const html = `<!doctype html><meta charset="utf-8"><body>:pr: <a href="${escapeHtml(prUrl)}">${escapeHtml(title)}</a> <code>${additionsText}</code> <code>${deletionsText}</code></body>`;

const textutil = Bun.spawn(
  ["textutil", "-convert", "rtf", "-format", "html", "-stdin", "-stdout"],
  {
    stdin: "pipe",
    stdout: "pipe",
    stderr: "pipe",
  },
);
textutil.stdin.write(html);
textutil.stdin.end();

const [rtf, textutilError, textutilExitCode] = await Promise.all([
  new Response(textutil.stdout).arrayBuffer(),
  new Response(textutil.stderr).text(),
  textutil.exited,
]);

if (textutilExitCode !== 0) {
  console.error(
    textutilError.trim() || "Failed to create rich clipboard text.",
  );
  process.exit(textutilExitCode);
}

// pbcopy recognizes RTF, but it does not provide valid plain-text clipboard
// data alongside it on current macOS versions. Write plain text, semantic HTML,
// and RTF to one pasteboard item. Slack uses HTML's <a> and <code> elements to
// retain both the hyperlink and native inline-code formatting.
const clipboardScript = `
ObjC.import("AppKit");
function run(argv) {
  const pasteboard = $.NSPasteboard.generalPasteboard;
  const item = $.NSPasteboardItem.alloc.init;
  const html = $.NSData.alloc.initWithBase64EncodedStringOptions(argv[1], 0);
  const rtf = $.NSData.alloc.initWithBase64EncodedStringOptions(argv[2], 0);

  item.setStringForType(argv[0], $.NSPasteboardTypeString);
  item.setDataForType(html, $.NSPasteboardTypeHTML);
  item.setDataForType(rtf, $.NSPasteboardTypeRTF);
  pasteboard.clearContents;

  if (!pasteboard.writeObjects($.NSArray.arrayWithObject(item))) {
    throw new Error("Failed to write to the clipboard");
  }
}
`;
const clipboard = Bun.spawn(
  [
    "osascript",
    "-l",
    "JavaScript",
    "-e",
    clipboardScript,
    "--",
    slackMessage,
    Buffer.from(html).toString("base64"),
    Buffer.from(rtf).toString("base64"),
  ],
  { stderr: "pipe" },
);

const [clipboardError, clipboardExitCode] = await Promise.all([
  new Response(clipboard.stderr).text(),
  clipboard.exited,
]);
if (clipboardExitCode !== 0) {
  console.error(
    clipboardError.trim() ||
      "Failed to copy the Slack message to the clipboard.",
  );
  process.exit(clipboardExitCode);
}

console.log(slackMessage);
console.log("Copied to clipboard with Slack-compatible rich formatting.");
