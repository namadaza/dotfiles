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
const slackMessage = `:pr: ${title} \`${additionsText}\` \`${deletionsText}\``;

// Match Slack's own clipboard delta: only the title is linked, and the diff
// counts are inline code. Slack can prefer this over generic HTML on paste.
const slackRichText = JSON.stringify({
  ops: [
    { insert: { slackemoji: { text: ":pr:" } } },
    { insert: " " },
    { attributes: { link: prUrl }, insert: title },
    { insert: " " },
    { attributes: { code: true }, insert: additionsText },
    { insert: " " },
    { attributes: { code: true }, insert: deletionsText },
  ],
});

// Chromium/Electron stores custom clipboard MIME types in a Pickle: a payload
// size, entry count, then length-prefixed UTF-16LE strings aligned to 4 bytes.
const uint32 = (value: number) => {
  const buffer = Buffer.alloc(4);
  buffer.writeUInt32LE(value);
  return buffer;
};
const pickleString = (value: string) => {
  const bytes = Buffer.from(value, "utf16le");
  return Buffer.concat([
    uint32(bytes.length / 2),
    bytes,
    Buffer.alloc((4 - (bytes.length % 4)) % 4),
  ]);
};
const customEntries = [
  ["public.utf8-plain-text", `:pr: ${title} ${additionsText} ${deletionsText}`],
  ["slack/texty", slackRichText],
];
const customPayload = Buffer.concat([
  uint32(customEntries.length),
  ...customEntries.flatMap(([type, value]) => [
    pickleString(type),
    pickleString(value),
  ]),
]);
const customData = Buffer.concat([uint32(customPayload.length), customPayload]);

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

// Write Slack's native rich-text data alongside HTML, RTF, and plain text.
// The latter formats remain available for paste targets other than Slack.
const clipboardScript = `
ObjC.import("AppKit");
function run() {
  const input = $.NSFileHandle.fileHandleWithStandardInput.readDataToEndOfFile;
  const argv = JSON.parse(ObjC.unwrap(
    $.NSString.alloc.initWithDataEncoding(input, $.NSUTF8StringEncoding)
  ));
  const pasteboard = $.NSPasteboard.generalPasteboard;
  const item = $.NSPasteboardItem.alloc.init;
  const html = $.NSData.alloc.initWithBase64EncodedStringOptions(argv[1], 0);
  const rtf = $.NSData.alloc.initWithBase64EncodedStringOptions(argv[2], 0);
  const customData = $.NSData.alloc.initWithBase64EncodedStringOptions(argv[3], 0);

  item.setDataForType(customData, "org.chromium.web-custom-data");
  item.setStringForType(argv[0], $.NSPasteboardTypeString);
  item.setDataForType(html, $.NSPasteboardTypeHTML);
  item.setDataForType(rtf, $.NSPasteboardTypeRTF);
  pasteboard.clearContents;

  if (!pasteboard.writeObjects($.NSArray.arrayWithObject(item))) {
    throw new Error("Failed to write to the clipboard");
  }
}
`;
// Keep clipboard payloads off the command line: osascript can be killed
// before execution when invoked with large argument payloads.
const clipboard = Bun.spawn(
  ["osascript", "-l", "JavaScript", "-e", clipboardScript],
  { stdin: "pipe", stderr: "pipe" },
);
clipboard.stdin.write(JSON.stringify([
  slackMessage,
  Buffer.from(html).toString("base64"),
  Buffer.from(rtf).toString("base64"),
  customData.toString("base64"),
]));
clipboard.stdin.end();

const [clipboardError, clipboardExitCode] = await Promise.all([
  new Response(clipboard.stderr).text(),
  clipboard.exited,
]);
if (clipboardExitCode !== 0) {
  console.error(
    clipboardError.trim() ||
      `Failed to copy the Slack message to the clipboard (exit ${clipboardExitCode}${clipboard.signalCode ? `, signal ${clipboard.signalCode}` : ""}).`,
  );
  process.exit(clipboardExitCode);
}

console.log(slackMessage);
console.log("Copied to clipboard with Slack-compatible rich formatting.");
