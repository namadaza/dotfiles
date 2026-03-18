# Testing

Three testing approaches, in order of priority:

## 1. Integration Tests

Backend integration tests validate services, workflows, and database operations against real infrastructure (DB, external APIs). These are the primary automated tests.

### Setup

Look for an existing integration test config in the app being worked on (e.g., `vitest.integration.config.mts`). If one exists, follow its patterns exactly. If not, create one modeled on this structure:

```ts
// vitest.integration.config.mts
import { defineConfig } from 'vitest/config';
import tsconfigPaths from 'vite-tsconfig-paths';
import dotenv from 'dotenv';

dotenv.config({ path: '.env.local' });

export default defineConfig({
  plugins: [tsconfigPaths()],
  test: {
    include: ['tests/integration/**/*.test.ts'],
    environment: 'node',
    testTimeout: 120_000,
    hookTimeout: 30_000,
  },
});
```

Key points:
- Load `.env.local` for database and API credentials.
- Use `environment: 'node'` (not jsdom).
- Set generous timeouts -- integration tests hit real services.
- **Local dev DB is safe to write to.** You can make direct DB calls or use service functions to create fixture data for tests. No need to mock the database -- the local environment always points to a development database.

### Patterns

- **File structure**: `tests/integration/<feature>/<name>.test.ts`
- **Fixtures**: Shared test data and helpers in `tests/integration/fixtures.ts`
- **Cleanup**: Track created records and delete them in `afterEach` so tests are idempotent.
- **Assertions**: Validate multiple properties per test -- don't just check for truthiness, verify types, formats, and expected values.

```ts
import { describe, it, expect, afterEach } from 'vitest';

const createdIds: string[] = [];

afterEach(async () => {
  for (const id of createdIds) {
    await deleteTestRecord(id);
  }
  createdIds.length = 0;
});

describe('entityCreate', () => {
  it('creates a record and returns a valid ID', async () => {
    const result = await entityCreate({ name: 'Test' });
    createdIds.push(result.id);

    expect(result.id).toBeTruthy();
    expect(typeof result.id).toBe('string');
    expect(result.name).toBe('Test');
  });
});
```

### Running

Check the app's `package.json` for the integration test script. Typically:
```bash
pnpm --filter <app-name> test:integration
```

## 2. Unit Tests

Unit tests validate pure logic, utilities, and transformations in isolation. Use vitest with the default config (jsdom environment for frontend, node for backend utilities).

### Patterns

- **File structure**: Colocate unit tests next to the source file (`foo.test.ts` next to `foo.ts`), or in a `tests/unit/` directory -- match whatever the project already does.
- **No mocking by default.** Test real functions with real inputs. Only mock external I/O (network, database) when absolutely necessary.
- **Fast and focused.** Each test should validate one behavior. No setup of external services.

```ts
import { describe, it, expect } from 'vitest';

describe('formatCurrency', () => {
  it('formats USD amounts', () => {
    expect(formatCurrency(1000, 'USD')).toBe('$1,000.00');
  });

  it('handles zero', () => {
    expect(formatCurrency(0, 'USD')).toBe('$0.00');
  });
});
```

### Running

Check the app's `package.json` for the test script. Typically:
```bash
pnpm --filter <app-name> test
```

## 3. Agentic Browser Testing

**Required for any spec that adds or changes UI.** This is not optional -- it is the final validation gate before a UI-facing spec can be marked complete. Integration tests verify data flow; browser testing verifies the user actually sees and can interact with what was built.

Use [agent-browser](https://agent-browser.dev) to verify the feature works end-to-end in the browser. This is not automated test code -- it is an agent-driven browser you interact with directly.

### Commands

agent-browser uses individual CLI commands chained together. There is no natural-language `do` command -- you must use the specific commands below.

```bash
# Navigate
npx agent-browser open <url>

# Inspect -- get interactive elements with @ref handles
npx agent-browser snapshot -i

# Interact (use @ref from snapshot output)
npx agent-browser click @e5
npx agent-browser fill @e6 "text value"
npx agent-browser type @e6 "appended text"
npx agent-browser select @e7 "option-value"
npx agent-browser check @e8
npx agent-browser press Enter

# Wait
npx agent-browser wait 2000            # milliseconds
npx agent-browser wait @e5             # wait for element

# Screenshots
npx agent-browser screenshot /tmp/page.png
npx agent-browser screenshot --full /tmp/full-page.png
npx agent-browser screenshot --full --annotate /tmp/annotated.png

# JavaScript (escape hatch for React/Radix components)
npx agent-browser eval "document.querySelector('button[value=\"x\"]').click()"

# Cleanup
npx agent-browser close
```

**Radix UI workaround:** `click @ref` on Radix RadioGroup items may not trigger React's `onValueChange`. Use `eval` to click the underlying DOM element directly: `npx agent-browser eval "document.querySelector('button[value=\"<value>\"]').click()"`.

### Workflow

The dev server must be running first. Start it if it isn't (e.g., `pnpm --filter <app-name> dev`).

Typical flow:
1. `open <url>` -- navigate to the page
2. `snapshot -i` -- see interactive elements and their `@ref` handles
3. `fill`/`click`/`select` -- interact using `@ref` handles from the snapshot
4. `snapshot -i` again -- verify state changed (refs may shift after DOM updates, re-snapshot before interacting)
5. `screenshot --full /tmp/name.png` -- capture the result
6. Repeat for each page/flow
7. `close` -- end the session

### What to verify

- Every new page renders without errors.
- Primary user flows work end-to-end (fill a form, submit, see result; click filters, see list update; expand/collapse cards).
- Conditional UI shows/hides correctly (e.g., fields that appear based on a selection).
- Navigation between new pages works (sidebar links, internal links, back buttons).

### When to use

- **Always** after implementing a UI-facing spec, before marking it complete (loop step 8b).
- When integration tests alone can't verify the user experience (layout, interactions, visual feedback).
- **Skip only** for backend-only specs with zero UI changes (no new pages, no component modifications).

## General Rules

- **Prefer integration tests** for service-layer code, workflows, and anything that touches the database or external APIs.
- **Prefer unit tests** for pure functions, data transformations, and utilities.
- **Use agentic browser testing** as a final verification for UI features.
- **No snapshot tests.** They break constantly and provide little value.
- **No mocking unless necessary.** Real calls to real services in integration tests. Only mock when a service is destructive, rate-limited, or costs money per call.
- **Always clean up test data.** Tests should leave the database in the same state they found it.
