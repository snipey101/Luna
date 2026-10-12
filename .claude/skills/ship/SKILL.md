---
name: ship
description: Verify, build and publish Luna changes. Runs the gameplay tests several times, exports the Windows build, checks the docs are up to date, then commits and pushes to GitHub (and optionally creates a release with Luna.exe). Use when the user says ship, release, "commit and push", or "push this".
---

# Ship Luna

Run from the repo root (`/Users/paulwatkins/code/luna`). Stop and report if any step fails. Don't push a red build.

1. **See what's changing:** `git status --short` and `git diff --stat`. If there's nothing to commit and nothing to push (`git status -sb` isn't ahead), say so and stop.

2. **Test, repeatedly.** Run `make test` 3 times (5 if dog AI, needs or tests changed). Each run must end with `ALL PASSED`. If one fails:
   - Rerun the failing check with diagnostics and find the cause (see CLAUDE.md → Tests). Fix the real problem, or make the test geometry-independent if the test itself is at fault.
   - Never skip, delete or loosen a check just to get green without explaining why to the user.

3. **Re-import if assets changed** (`.glb`, `.wav` or the generator scripts): run `Godot --headless --path game --import` twice.

4. **Export:** `make windows`, then confirm `build/Luna.exe` has a fresh timestamp. A missing or failed export means the templates are gone. See CLAUDE.md → Tooling.

5. **Docs check.** Ask yourself, and fix anything missing:
   - Did controls or rules change? Update the README "How to play", the HUD hint, the pause-panel text and the title-screen controls line.
   - Was this a significant gameplay or architecture decision? Add an ADR and a row in `docs/adr/README.md`.
   - New debug flags? Add them to the README and CLAUDE.md.

6. **Commit:** `git add -A`, then a commit message with a short subject line (imperative mood) and a bullet list of the main changes. End it with the Co-Authored-By line from the current attribution guidance. Don't commit `build/` or `.godot/` (they're gitignored, so check nothing slipped in).

7. **Push:** `git push`. If it's rejected because the remote moved, `git fetch` and look at what's there before doing anything. Only force push (`--force-with-lease`) if the user explicitly says to.

8. **Release (only if the user asks):**
   ```sh
   gh release create vX.Y build/Luna.exe --title "Luna vX.Y" --notes "<summary of changes>"
   ```
   Check existing tags first with `gh release list`. The repo is public, so the release is too.

9. **Report:** the commit hash(es), test results (e.g. "3/3 runs passed"), the export size and timestamp, any docs updated, and the release URL if one was made.
