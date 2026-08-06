SYSTEM: Pi coding agent configuration

Guidelines for Pi (agent) inside this folder:

Session title

- At the beginning of a new, unnamed session, call the `set_session_title` tool once before doing substantive work.
- Choose a concise, descriptive title of 2–5 words based on the user's initial request (for example, `Add session status line`).
- Do not call it when the session already has a title, and do not rename an existing title unless the user explicitly asks.

Git

- Make changes, do not stage them. User will manually review, then stage and commit.

Next.js / React preferences:

- Prefer using react-query (TanStack Query) for client-side data fetching and mutations in Next.js/React environments. Use useQuery/useMutation for caching, background refetch, and optimistic updates instead of ad-hoc fetch calls in client components.

- Prefer Next.js Server Actions over creating additional API endpoints when possible. Place server-side business logic into a lib/ or services/ folder, then create a *-actions.ts file with the "use server" directive at the top and export the server action functions from there. These server actions can then be invoked from client-side mutation handlers (e.g. useMutation) or form actions.

  Example convention:
  - lib/user-actions.ts
    "use server"
    export async function updateUser(data) { /* ... */ }

  This keeps server logic organized in lib/ or services/, avoids scattering endpoint handlers, and makes it straightforward to call server actions from client-side mutation code.
