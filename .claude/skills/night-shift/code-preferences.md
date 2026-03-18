# Code Preferences

## General

- **No dynamic imports.** Never use `next/dynamic` or `import()` for code splitting. Import everything statically.
- **No enums.** Use string literal unions and const objects instead of TypeScript enums. Also avoid Postgres enums -- use plain `text` columns and constrain values in application code (Zod schemas, const arrays). This avoids migrations when adding/removing values and keeps the database simple.
- **Zod for validation.** Use Zod schemas for API request validation. Infer types from schemas with `z.infer<>`.
- **Minimal abstractions.** Don't create helpers or wrappers for one-time operations. Three similar lines > a premature abstraction.
- **Match existing patterns.** Before writing new code, read adjacent files to understand the project's conventions for imports, naming, file structure, and error handling. Follow what's already there.

## Backend

### Server Actions as the Default

Prefer server actions (`'use server'`) over API routes for data fetching and mutations. API routes are reserved for:
- External consumers (webhooks, third-party integrations)
- Streaming responses
- Webhook endpoints

Look for a `services/` directory in the codebase -- service files typically start with `'use server'`.

### Service Layer Naming

Verb-first, domain-prefixed: `entityCreate`, `entityById`, `entitiesByParentId`, `entityUpdate`, `entityDelete`.

- Query functions: `{entity}ById`, `{entities}By{Parent}Id`
- Mutations: `{entity}Create`, `{entity}Update`, `{entity}Delete`

### Database (Drizzle ORM)

Look for a `db` package or directory in the monorepo. Schema files, relations, and migrations will be colocated there.

#### Migrations

We use Drizzle Kit's `generate` command to produce SQL migration files from schema changes -- never write migration SQL by hand. The workflow:

1. Edit the relevant schema file.
2. Find and run the drizzle generation command in the `package.json` (look for scripts like `gen`, `generate`, `db:generate`, etc.).
3. Find and run the drizzle migration command in the `package.json` (look for scripts like `migrate`, `db:migrate`, etc.). This is safe to run locally as local environments use a development database.

Never edit generated migration files.

#### Prefer JSONB Columns for Flexible Data

When a feature needs structured data that may evolve over time, prefer a typed JSONB column over adding many individual columns. This keeps the schema lean and avoids constant migrations for field additions.

The pattern: define a Zod schema for the shape, infer the type, and use `.$type<T>()` on the JSONB column.

```ts
// 1. Zod schema for validation + type inference
export const OptionsSchema = z.object({
  fontSize: z.number().optional(),
  lineSpacing: z.number().optional(),
  font: z.string().optional(),
})
export type Options = z.infer<typeof OptionsSchema>

// 2. Column definition with type annotation
options: jsonb().$type<Options>(),
```

Adding a new field to a JSONB column is just a schema/type change -- no migration needed. Use this for:
- Config/preferences objects
- Structured metadata
- Complex nested data

Add dedicated columns when the field needs to be indexed, queried with WHERE clauses, or enforced with constraints (foreign keys, unique, not null).

#### Query Patterns

- Use `db.transaction(async (tx) => { ... })` for multi-step writes
- Pass transactions via `opts?: { transaction?: tx }` parameter
- Null-check required params and throw descriptive errors: `throw new Error('entityById - entityId is required')`

### API Routes

When API routes are necessary:
- Zod-validate all inputs first
- Three-tier error handling: Zod errors (400), known errors (500), unknown errors (500)
- Set `maxDuration` for long-running AI endpoints
- Return `NextResponse.json()` with appropriate status codes

### Error Handling (Backend)

- Validate required params early and throw descriptive errors
- Workers use `job.log()` for logging, throw to trigger failure callbacks

## Frontend

### React Query for Everything

Server actions are called from the frontend via React Query's `useQuery` and `useMutation`. Never call server actions directly in components without wrapping them in React Query.

```tsx
// Queries
const { data } = useQuery({
  queryKey: ['entity', id],
  queryFn: async () => await entityById({ entityId: id }),
})

// Mutations
const { mutate } = useMutation({
  mutationFn: async (params) => await entityCreate(params),
  onSuccess: () => queryClient.invalidateQueries({ queryKey: ['entities'] }),
})
```

Look for a centralized query key object or constants file in the app. Always invalidate relevant queries after mutations.

### Component Organization

**Naming:**
- Files: kebab-case (`general-chat.tsx`, `use-message-polling.tsx`)
- Components: PascalCase exports (`GeneralChat`)
- Hooks: `use` prefix, kebab-case files (`use-create-document.tsx`)

Follow the existing component folder structure in the app. Read the `components/` directory to understand the organization before adding new files.

### UI Stack

- **shadcn/ui** (Radix primitives + Tailwind) -- component library
- **Tailwind CSS** -- styling (no CSS modules, no styled-components)
- **`cn()`** utility for conditional class merging (find it in the shared utils)
- **Lucide React** -- icons
- **Framer Motion** -- animations
- **Sonner** -- toast notifications

Check `package.json` to confirm which of these are available in the current project.

### State Management

- **React Query** for all server state
- **`useState`** for local UI state
- No global state library (no Zustand, Redux, or Context for state)

### Forms

Plain HTML inputs with `useState` and `onChange` handlers. No form library (no react-hook-form). Zod is used for API validation, not form validation.

### Custom Hooks

Hooks encapsulate React Query logic and side effects. Common patterns:
- Polling hooks for async AI operations
- Mutation hooks that wrap `useMutation`
- Debounced save hooks for auto-saving fields

### Client vs Server Boundary

- `'use client'` at top of interactive components
- `'use server'` at top of service files
- Keep the boundary clean -- don't mix concerns in a single file

## Import Conventions

Follow the existing import patterns in the codebase. Typically:
- **Cross-package imports** use workspace aliases (e.g., `@repo/...` or `@package/...`). Read existing files to discover the alias convention.
- **App-local imports** use path aliases (e.g., `@/...`). Check `tsconfig.json` for the configured paths.
- Import directly from source files. Avoid barrel exports (`index.ts` re-exports) unless the project already uses them.
