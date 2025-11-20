# AI Refactoring Tool - Usage Guide

[Original post](https://x.com/VictorTaelin/status/1991145825318130054)

# REVIEW 11/18/2025

After using this for some time, I still think the Cursor/Claude Code experience is better. This format, though handy, and quick, often gets the code blocks mis-shaped, curly braces are wrong, it doesn't too changes across disparate repos in the file very well.

## Overview

This is an AI-powered code refactoring tool that reads a file containing code and instructions, then uses an AI model to generate and apply edits to your codebase.

## Prerequisites

1. **Bun**: The script uses Bun as the runtime. Install it if you haven't:

   ```bash
   curl -fsSL https://bun.sh/install | bash
   ```

2. **API Key**: Set up your Google API key:

   - Create a file at `vendors/google.token`
   - Add your Google API key to this file (one line, no extra whitespace)

3. **Dependencies**: Install dependencies:
   ```bash
   cd ai
   pnpm install
   ```

## Basic Workflow

### Step 1: Create a File with Code + Instructions

Create a file (e.g., `example.ts`) that contains:

1. **Code** - The code you want to refactor/edit
2. **Comment block** - Instructions describing what you want done

The comment block must be at the **end** of the file and use one of these comment styles:

- `//` for JavaScript/TypeScript
- `--` for Lua/Haskell
- `#` for Python/Shell

**Example:**

```typescript
// example.ts
function greet(name: string) {
  return `Hello, ${name}!`;
}

function add(a: number, b: number) {
  return a + b;
}

// Add JSDoc comments to all functions
// Make the greet function more formal
```

### Step 2: Run the Refactoring Script

```bash
cd /path/to/your/project
bun ~/.config/dotfiles/ai/refactor.ts example.ts [model]
```

**Arguments:**

- `example.ts` - The file containing your code and instructions (required)
- `[model]` - Optional model spec (defaults to `"g"` which maps to `google:gemini-3-pro-preview:medium`)

**Model Options:**

- `g` or `i` - Default Gemini model (medium thinking)
- `i-` - Low thinking level
- `i+` or `I` - High thinking level
- Custom: `google:gemini-3-pro-preview:high`

### Step 3: Review the Changes

The script will:

1. Extract your code and instructions
2. Follow imports to collect related files
3. Optionally compact the context if it's too large (>16k tokens)
4. Call the AI model to generate edit commands
5. Apply the edits automatically

**Output locations:**

- Session logs are saved to `~/.ai/refactor-history/`
- Latest prompts/responses: `~/.ai/refactor-full-prompt.txt`, `~/.ai/refactor-mini-prompt.txt`, `~/.ai/refactor-response.txt`

## How It Works

### Context Collection

The tool automatically:

- Reads the target file
- Follows all `import` statements (ES6 imports, CommonJS requires, C `#include`, etc.)
- Builds a context map of all related files
- Splits files into "blocks" (sequences of non-empty lines)

### Context Compaction

If the context is large (>16k tokens) and has imports:

- First calls a "compaction" model to identify irrelevant blocks
- Removes blocks that aren't needed for the task
- Then calls the main editing model with the compacted context

### Edit Commands

The AI generates commands in XML-like format:

- `<write file=path>...</write>` - Write/replace entire file
- `<patch id=BLOCK_ID>...</patch>` - Replace a specific block
- `<delete file=path/>` - Delete a file

### Block-Based Editing

Files are split into blocks (sequences of non-empty lines separated by blank lines). This allows:

- Precise edits to specific parts of large files
- Merging blocks (move content, delete empty block)
- Splitting blocks (add empty lines)

## Examples

### Example 1: Simple Refactoring

**File: `math.ts`**

```typescript
function add(a, b) {
  return a + b;
}

function multiply(a, b) {
  return a * b;
}

// Add TypeScript types to all parameters
// Add return type annotations
```

**Command:**

```bash
bun ~/.config/dotfiles/ai/refactor.ts math.ts
```

### Example 2: Multi-File Refactoring

**File: `main.ts`**

```typescript
import { helper } from "./helper.ts";

export function process(data: string) {
  return helper(data);
}

// Refactor to use async/await
// Add error handling
```

The tool will automatically include `helper.ts` in the context.

### Example 3: Using Different Models

```bash
# Use high thinking level
bun ~/.config/dotfiles/ai/refactor.ts example.ts i+

# Use low thinking level (faster, cheaper)
bun ~/.config/dotfiles/ai/refactor.ts example.ts i-
```

## Tips

1. **Be specific**: Clear instructions produce better results
2. **One task at a time**: Focus on a single refactoring task per run
3. **Review changes**: Always review the generated code before committing
4. **Git integration**: The tool automatically stages new files with `git add` if you're in a git repo
5. **Large codebases**: The compaction feature helps with large projects

## Troubleshooting

**Error: "File must end with a comment block"**

- Make sure your instructions are at the end of the file
- Use `//`, `--`, or `#` comment style

**Error: "missing import"**

- The tool warns about missing imports but continues
- Make sure all imported files exist

**Model errors**

- Check that `~/.config/google.token` exists and contains a valid API key
- Verify your API key has access to Gemini models

## Advanced Usage

### Making the Script Executable

You can make the script directly executable:

```bash
chmod +x ~/.config/dotfiles/ai/refactor.ts
```

Then use it directly:

```bash
./refactor.ts example.ts
```

Or create an alias:

```bash
alias refactor="bun ~/.config/dotfiles/ai/refactor.ts"
refactor example.ts
```
