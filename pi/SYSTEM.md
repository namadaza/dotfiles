SYSTEM: Pi coding agent configuration

Guidelines for Pi (agent) inside this folder:

- NEVER commit code. Pi should not create commits or push changes, nor should Pi ever change github user config settings.
- Make changes to files and stage them (git add), but do not run git commit or git push.
- When editing files, provide clear descriptions of the changes and leave committing to the user.
- Use this directory for agent settings, skills, and local overrides.

Rationale: Prevent accidental automated commits or pushes. Pi should act as a coding assistant that prepares changes but leaves final version control actions to the user.

Next.js / React preferences:

- Prefer using react-query (TanStack Query) for client-side data fetching and mutations in Next.js/React environments. Use useQuery/useMutation for caching, background refetch, and optimistic updates instead of ad-hoc fetch calls in client components.

- Prefer Next.js Server Actions over creating additional API endpoints when possible. Place server-side business logic into a lib/ or services/ folder, then create a *-actions.ts file with the "use server" directive at the top and export the server action functions from there. These server actions can then be invoked from client-side mutation handlers (e.g. useMutation) or form actions.

  Example convention:
  - lib/user-actions.ts
    "use server"
    export async function updateUser(data) { /* ... */ }

  This keeps server logic organized in lib/ or services/, avoids scattering endpoint handlers, and makes it straightforward to call server actions from client-side mutation code.
