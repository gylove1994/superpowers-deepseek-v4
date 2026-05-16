---
name: resume-brainstorming
description: Use as the strict first step every time the brainstorming SKILL is about to start. Scans existing decision logs in docs/superpowers/brainstorms/ and either continues an In Progress session, starts a new session based on a Done or Abandoned session, or (when no logs exist) lets brainstorming proceed with a fresh empty file.
---

# Resume Brainstorming

## When to invoke

This SKILL is the first step of every `brainstorming` invocation. The refactored `brainstorming` SKILL calls this before doing anything else.

**Announce at start:** "I'm using the resume-brainstorming SKILL to check for existing sessions."

## What it does

1. Scan `docs/superpowers/brainstorms/*-brainstorm.md`.
2. Bucket files by `Status` metadata: `In Progress`, `Done`, `Abandoned`.
3. If all three buckets are empty → return `proceed-with-new-empty` (the brainstorming SKILL then creates a fresh empty file using `templates/brainstorm-template.md`).
4. Otherwise → present the menu (see below) and act on the user's choice.

## Menu shown to the user

```
docs/superpowers/brainstorms/ status:

In Progress (N):
  [1] <date>-<slug>-brainstorm.md   — <topic>   Current Phase: <phase>
  [2] ...

Done (M, most recent 5 shown):
  [d1] <date>-<slug>-brainstorm.md  — <topic>
  ...

Abandoned (K):
  [a1] <date>-<slug>-brainstorm.md  — <topic>
  ...

Please choose:
  A) Continue an In Progress session       → enter the number (e.g. "1")
  B) Start a new session based on a Done   → enter "new based on <id>" (e.g. "new based on d1")
  C) Start a new session based on an Abandoned → enter "new based on <id>"
  D) Abandon an In Progress session        → enter "abandon <number>"
```

If `In Progress` is empty, omit option A and option D.
If `Done` is empty, omit option B.
If `Abandoned` is empty, omit option C.
If after these omissions no options remain (only possible if all three buckets are empty, which Step 3 already handles), bypass the menu and return `proceed-with-new-empty`.

## Acting on the user's choice

### A — Continue In Progress

1. Read the chosen file in full.
2. Inform the main flow agent: "Continuing brainstorming from `<filename>`. Current Phase: `<phase>`."
3. Hand the file path and parsed `Current Phase` value back to the brainstorming SKILL. The brainstorming SKILL then resumes from the appropriate point per the table below.

### B — Start new, based on a Done file

1. Read the Done file in full.
2. Compute a new `<topic-slug>` (ask the user if uncertain) and create `docs/superpowers/brainstorms/<today>-<slug>-brainstorm.md` by copying the template, then setting `Based On: <Done filename>` in the header.
3. Inject the Done file's full content as a "Prior Discussion (basis for this new round)" reference for the main flow agent's context. It is not copied verbatim into the new file; the `Based On` link is the on-disk record.
4. Return: new file path, `Current Phase: alignment`, plus the prior file content as context for the brainstorming SKILL to begin its Phase A questions.

### C — Start new, based on an Abandoned file

Same as B, but the rationale for abandonment (if recorded in the file) is also surfaced to the user as context: "Previously abandoned because: <reason>. We are restarting on that basis."

### D — Abandon an In Progress

1. Open the chosen file.
2. Set `Status: Abandoned`.
3. Append a section:
   ```
   ## Abandonment

   **Timestamp:** YYYY-MM-DD HH:MM
   **Reason:** <ask the user, or "User requested without specific reason">
   ```
4. `git add <file> && git commit -m "abandon brainstorm: <topic>"`
5. Re-run this SKILL (the user may now want to choose a different option from the updated menu).

## Current Phase precise recovery (for option A)

When the brainstorming SKILL receives a `Current Phase` from option A, it resumes as follows:

| Current Phase | Resume behaviour |
|---|---|
| `alignment` | Read the Phase A decision log. Continue asking from `Q<n+1>`. |
| `spec_writing` | Read the "Alignment Summary" section. Continue from the draft on disk. |
| `review_round_N` | Re-dispatch round N's reviewers (the draft is in the working directory, unchanged because mid-loop commits never happen). |
| `awaiting_user_decision` | Re-present the open `I<n>` block(s) to the user. |
| `finalizing` | Re-present the converged draft for final sign-off. |

## What this SKILL does NOT do

- It does not modify the chosen file (except option D's abandonment edit).
- It does not start the brainstorming flow itself; it only sets up state.
- It does not commit anything except in option D.
- It does not auto-decide; the user always picks from the menu.

## File referenced

- `./templates/brainstorm-template.md` — the verbatim template used when creating new files.
