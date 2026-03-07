---
description: Auto-upload the chat log to GitHub after every session
---

# Auto Chat Log Upload

This workflow runs AUTOMATICALLY at the END of every conversation in the Lexi-Core workspace. It updates `LEXI_CHAT_LOG.md` with the **full verbatim** session content and pushes to GitHub.

## When to Trigger

- **After EVERY chat interaction** — not just at the end of a multi-prompt session
- This means: every time you finish responding to a user prompt, append the log entry and push

## Steps

1. Read the current `LEXI_CHAT_LOG.md` to find the last session entry.

2. Append a new session block using this **exact format**:

```markdown
## Session — YYYY-MM-DD HH:MM

### 🧑 Prompt

> [Exact user prompt text — verbatim, in blockquote]

### 🤖 Response

[FULL detailed response — this is NOT a summary. Include ALL of the following:]

**What to log (MANDATORY):**
- Every step taken, numbered (Step 1, Step 2, etc.)
- Exact file paths modified with line numbers
- Complete error tracebacks (full stack trace, not abbreviated)
- Code snippets showing the exact fix applied (use fenced code blocks)
- All terminal commands run and their output
- API test results with HTTP status codes
- Flutter/backend build output and timing
- Crash root causes and fix explanations
- Git commit hashes and push results

**What NOT to do:**
- ❌ Do NOT summarize — write the full content
- ❌ Do NOT abbreviate error messages
- ❌ Do NOT skip intermediate steps
- ❌ Do NOT take browser screenshots (this is a Windows desktop app)
- ❌ Do NOT use the browser_subagent tool for verification

---
```

3. If there were multiple prompts in the session, log each one as a separate `### 🧑 Prompt` / `### 🤖 Response` pair under the same `## Session` header. Use `### 🧑 Follow-up Prompt` for subsequent prompts.

// turbo
4. Stage the chat log:
```powershell
git add LEXI_CHAT_LOG.md
```

// turbo
5. Commit with a descriptive message:
```powershell
git commit -m "docs: auto-update chat log — SESSION_DESCRIPTION"
```
Replace `SESSION_DESCRIPTION` with a brief summary of what was done (e.g. "sidebar redesign", "quiz null fix").

// turbo
6. Push to GitHub:
```powershell
git push origin main
```

## Important Rules

- **NEVER summarize** — log the FULL verbatim content of every prompt and response
- **Include ALL details** — code changes, file names, line numbers, test results, error tracebacks, terminal output
- **Use exact format** — session header → prompt (blockquote) → response (numbered steps)
- **Skip browser screenshots** — this is a Windows desktop app, do NOT use browser_subagent
- **Auto-trigger** — run this at the END of every completed response, not just at session end
- **Date format** — use the local time provided by the system metadata (YYYY-MM-DD HH:MM)
- **Commit messages** — always use `// turbo` annotation for git commands (auto-run)
