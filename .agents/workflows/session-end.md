---
description: End-of-session workflow — update chat log, changelog, README, settings, and push to GitHub
---

# End-of-Session Auto-Push

This workflow runs at the END of every coding session. It ensures all documentation is up to date and everything is pushed to GitHub before closing.

## When to Trigger

- **At the end of every session** — after all coding/debugging work is done
- **Before the user closes the conversation**
- Can also be invoked manually with `/session-end`

## Steps

### 1. Update `LEXI_CHAT_LOG.md`

Append a detailed session entry at the **top** of the file (below the header `# Lexi-Core — Chat Log`, before existing sessions).

**Format:**

```markdown
### YYYY-MM-DD — [short session title]

User request:
- [Bullet points summarizing what the user asked for]

[For each major action taken, document:]

**Step N: [action title]**

Modified files:
- `path/to/file.ext:line_number` — [what changed]

[Include code snippets, terminal commands, error tracebacks, test results, API responses, git output — be detailed and precise]

---
```

**Rules:**
- ❌ Do NOT summarize — write FULL details
- ✅ Include exact file paths with line numbers
- ✅ Include all terminal commands and their output
- ✅ Include code snippets showing exact fixes (fenced code blocks)
- ✅ Include test results, HTTP status codes, git hashes
- ✅ Include error tracebacks in full

### 2. Update `CHANGELOG.md` (if code was changed)

If any code, features, or bug fixes were made during this session:
- Add entries under the current version section
- Use the existing format: `### ✨ New Features`, `### 🐛 Bug Fixes`, `### 🛠 Fixes`, `### 📁 Files Modified`
- If a new version was bumped, add a new `## [version] — date` section

**Skip this step** if the session was documentation-only.

### 3. Update `README.md` (if applicable)

Update if any of the following changed during the session:
- New features added → update **Key Features** section
- New API endpoints → update **API Reference** tables
- Architecture changed → update **Architecture** tree
- Version bumped → update version in banner and roadmap
- New AI models → update **Supported AI Models** table

**Skip this step** if nothing in the README is outdated.

### 4. Update `settings_page.dart` About section (if applicable)

File: `ui/lib/pages/settings_page.dart`

If the version was bumped or features changed, update the `_InfoRow` entries in the About section:
- `Version` value
- `AI Models` value
- `Features` value
- Any other outdated info

**Skip this step** if the About section is already accurate.

### 5. Stage all changed docs

// turbo
```powershell
git add LEXI_CHAT_LOG.md CHANGELOG.md README.md ui/lib/pages/settings_page.dart
```
Only stage files that were actually modified. Use `git add -A` if other source files were also changed.

### 6. Commit with descriptive message

// turbo
```powershell
git commit -m "docs: auto-update chat log — SESSION_DESCRIPTION"
```
Replace `SESSION_DESCRIPTION` with a brief summary (e.g. "quiz fix session", "GitHub setup", "flashcard redesign").

If source code was also changed, use a more appropriate prefix:
- `fix:` for bug fixes
- `feat:` for new features
- `docs:` for documentation-only changes

### 7. Push to GitHub

// turbo
```powershell
git push origin main
```

### 8. Verify push

// turbo
```powershell
git log --oneline -n 3; git status
```

Confirm:
- New commit is at HEAD
- Branch is "up to date with origin/main"
- No untracked source files left behind

## Important Rules

- **ALWAYS run this workflow** — every session must end with chat log + push
- **Be detailed in the chat log** — this is for academic/teacher review; include ALL steps, code, and output
- **Don't commit log files** — unstage `data/*.log`, `gcm-diagnose.log`, and similar runtime logs before committing
- **Don't commit user data** — check that `.gitignore` covers `data/*.db`, `.env`, `ai_config.json`
- **Date format** — use the local time from system metadata (YYYY-MM-DD)
- **Skip unchanged files** — only update CHANGELOG/README/settings if they actually need changes
