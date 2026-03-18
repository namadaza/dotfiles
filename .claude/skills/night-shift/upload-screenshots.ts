#!/usr/bin/env bun
/**
 * Upload screenshots to Vercel Blob storage.
 *
 * Usage:
 *   bun upload-screenshots.ts <file1.png> [file2.png ...]
 *
 * Requires BLOB_READ_WRITE_TOKEN in the environment.
 *
 * Outputs one line per file: <local_path> -> <blob_url>
 */

import { put } from "@vercel/blob";
import { readFile } from "node:fs/promises";
import { basename } from "node:path";

const token = process.env.BLOB_READ_WRITE_TOKEN;
if (!token) {
  console.error("BLOB_READ_WRITE_TOKEN is not set in the environment.");
  process.exit(1);
}

const files = process.argv.slice(2);
if (files.length === 0) {
  console.error("Usage: bun upload-screenshots.ts <file1.png> [file2.png ...]");
  process.exit(1);
}

for (const filePath of files) {
  const filename = basename(filePath);
  const content = await readFile(filePath);
  const { url } = await put(`screenshots/${filename}`, content, {
    access: "public",
    token,
  });
  console.log(`${filePath} -> ${url}`);
}
