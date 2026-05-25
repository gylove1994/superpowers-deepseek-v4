---
name: confirming-worktree-before-edit
description: Use before any file edit in a session when worktree preference has not yet been confirmed — asks whether to open a new worktree, records the choice once per session, and delegates setup to using-git-worktrees when accepted
---

# Confirming Worktree Before Edit

## Overview

Before modifying any file in this session, confirm whether the user wants an isolated worktree — but only once per session.

**Core principle:** Ask once. Record the choice. Delegate setup. Never edit before the gate when consent is still unknown.

**Scope:** All file edits — project source, configuration, skill documents, and any other writable path.

**Announce at start:** "I'm using the confirming-worktree-before-edit skill to confirm worktree preference before editing."

## Step 0: Skip Conditions

**Do NOT run this gate when any of these apply:**

1. **Read-only mode** — Ask mode, Plan mode, or any context where you cannot edit files. Skip entirely.

2. **Subagent dispatch** — If you were dispatched as a subagent (`<SUBAGENT-STOP>` in using-superpowers), skip. The **parent agent** must run this gate before dispatching you.

3. **Already in a linked worktree** — Run detection (same as using-git-worktrees Step 0):

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)

# Submodule guard — if this returns a path, treat as normal repo, not worktree
git rev-parse --show-superproject-working-tree 2>/dev/null
```

If `GIT_DIR != GIT_COMMON` (and not a submodule): already isolated. Record `worktree consent: asked, choice: skipped (already in worktree)` and proceed to Step 4.

4. **User already declared worktree preference** — User rules, instructions, or an earlier message in this session explicitly state worktree preference (create one / work in place / use `/worktree`). Honor it. Record `worktree consent: asked, choice: yes|no` matching that preference. Proceed to Step 3 or Step 4 as appropriate.

5. **Consent already recorded this session** — If you already recorded `worktree consent: asked, choice: ...` in this session, skip to Step 4. Never ask twice.

## Step 1: Session Gate

You are about to edit a file and none of the Step 0 skip conditions apply.

**STOP. Do not edit any file yet.**

Ask the user using this exact wording:

> Would you like me to set up an isolated worktree? It protects your current branch from changes.

Wait for the user's answer before proceeding.

## Step 2: Record Choice

Immediately after the user answers, record in your session notes:

```
worktree consent: asked, choice: yes
```

or

```
worktree consent: asked, choice: no
```

This record prevents duplicate asks for the rest of the session. Other skills (including using-git-worktrees) rely on it.

## Step 3: Execute Choice

**If choice is yes:**

**REQUIRED SUB-SKILL:** Use superpowers-deepseek-v4:using-git-worktrees

Do not call `git worktree add` directly — using-git-worktrees handles native tools, paths, setup, and baseline tests.

**If choice is no:**

Work in the current directory. Proceed to Step 4 without creating a worktree.

## Step 4: Proceed

Gate complete. Continue the calling skill's edit workflow (TDD, plan execution, debugging fix, etc.).

## Quick Reference

| Situation | Action |
|-----------|--------|
| Read-only / Ask / Plan mode | Skip gate |
| Subagent | Skip (parent runs gate) |
| Already in linked worktree | Record skipped, proceed |
| User rules declare preference | Honor + record, no ask |
| Consent already recorded | Skip ask, proceed |
| First edit, none of above | Ask exact question, record, execute |
| User says yes | Invoke using-git-worktrees |
| User says no | Work in place |

## Common Mistakes

### Editing before asking

- **Problem:** Jump straight to StrReplace/Write because the task seems small
- **Fix:** Step 1 is a hard stop before any file modification

### Asking twice

- **Problem:** User already answered; agent asks again on next edit
- **Fix:** Check session record from Step 0 condition 5

### Creating worktree without using-git-worktrees

- **Problem:** Agent runs `git worktree add` after user says yes
- **Fix:** Step 3 always delegates to using-git-worktrees

### Asking when already isolated

- **Problem:** User opened `/worktree` or EnterWorktree; agent still asks
- **Fix:** Step 0 detection + record skipped

## Red Flags

**Never:**
- Edit any file before this gate when consent is not yet recorded and Step 0 skips do not apply
- Ask twice in the same session after recording choice
- Create a worktree without user consent
- Use `git worktree add` when a native harness worktree tool exists (using-git-worktrees owns this)
- Re-ask because the edit "feels urgent" (pressure does not bypass the gate)

**Always:**
- Run Step 0 skip checks first
- Use the exact consent question wording in Step 1
- Record choice immediately after asking
- Delegate worktree setup to using-git-worktrees when user accepts

## Integration

**Called by:** test-driven-development, subagent-driven-development, executing-plans, systematic-debugging (Phase 4), dispatching-parallel-agents, receiving-code-review, writing-skills, and using-superpowers (ad-hoc edits).

**Delegates to:** superpowers-deepseek-v4:using-git-worktrees (when user accepts)
