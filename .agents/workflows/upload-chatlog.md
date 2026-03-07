---
description: Auto-upload the chat log to GitHub after every session
---

# Auto Chat Log Upload

This workflow runs at the end of every conversation to update `LEXI_CHAT_LOG.md` with the full session content and push to GitHub.

## Steps

1. Read the current `LEXI_CHAT_LOG.md` to find the last session entry.

2. Append a new session block to `LEXI_CHAT_LOG.md` with the current date/time, using this format:

```markdown
## Session — YYYY-MM-DD HH:MM

### 🧑 Prompt
[Full user prompt text]

### 🤖 Antigravity (Lexi) Response
[Full detailed response — NOT a summary. Include all code changes, commands run, test results, and explanations as they appeared in the conversation.]

---
```

3. If there were multiple prompts in the session, log each one as a separate `### 🧑 Prompt` / `### 🤖 Antigravity (Lexi) Response` pair under the same `## Session` header. Use `### 🧑 Follow-up Prompt` for subsequent prompts within the same session.

// turbo
4. Stage and commit the chat log:
```powershell
git add LEXI_CHAT_LOG.md
```

5. Commit with a descriptive message:
```powershell
git commit -m "docs: auto-update chat log — SESSION_DESCRIPTION"
```
Replace `SESSION_DESCRIPTION` with a brief summary of the session (e.g. "iOS 26 glass rebuild", "Phase 7 debugging").

// turbo
6. Push to GitHub:
```powershell
git push
```

## Important Rules

- **NEVER summarize** — log the full content of prompts and responses
- **Include all details** — code changes, file names, test results, error messages, commands run
- **Use the exact format** above — session header, prompt header, response header
- **Auto-run** this workflow at the END of every conversation in the Lexi-Core workspace
- **Date format** — use the local time from the system (YYYY-MM-DD HH:MM)
