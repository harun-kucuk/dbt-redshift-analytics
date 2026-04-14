Commit staged changes, push, and open a pull request.

Steps:
1. Run `git status` — if on `main`, stop and tell the user to switch to a feature branch first
2. Show a diff summary of all changes
3. Stage relevant files by name — never `git add .`, never stage `.env` or secrets
4. Commit with a concise imperative message focused on the "why"
5. `git push -u origin HEAD`
6. `gh pr create` with:
   - Title under 70 characters
   - Body: bullet-point summary + test plan checklist
   - Base: `main`
7. Return the PR URL

Never use `--no-verify`. One PR per logical change — if changes are unrelated, ask the user to split them.
