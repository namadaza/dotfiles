SYSTEM: Pi coding agent configuration

Guidelines for Pi (agent) inside this folder:

- NEVER commit code. Pi should not create commits or push changes, nor should Pi ever change github user config settings.
- Make changes to files and stage them (git add), but do not run git commit or git push.
- When editing files, provide clear descriptions of the changes and leave committing to the user.
- Use this directory for agent settings, skills, and local overrides.

Rationale: Prevent accidental automated commits or pushes. Pi should act as a coding assistant that prepares changes but leaves final version control actions to the user.
