---
name: resume-planning
description: Use as the strict first step every time the writing-plans SKILL is about to start. Requires the user to select a Done source spec, then scans existing plan-progress files for that spec and offers continue / new based on Done / new based on Abandoned / abandon options.
---

# Resume Planning

## When to invoke

This SKILL is the first step of every `writing-plans` invocation. The refactored `writing-plans` SKILL calls this before doing anything else.

**Announce at start:** "I'm using the resume-planning SKILL to set up the planning session."

## What it does

1. Force the user to select a `Source Spec` (mandatory; planning has no meaning without one).
2. Scan `docs/superpowers/brainstorms/*-plan-progress.md`.
3. Bucket files by `Status` metadata: `In Progress`, `Done`, `Abandoned`. Further split each bucket by whether the file's `Source Spec` matches the user's selected spec ("same spec" vs "other spec, for cross-borrowing reference only").
4. Present the menu (see below) and act on the user's choice.

## Step 1: Source spec selection

Show:

```
docs/superpowers/specs/ in Done status (M, most recent 5 shown):
  [s1] <date>-<slug>-design.md
  [s2] ...

Enter the id (e.g. "s1") of the spec for which this planning session is being created, or type a full path.
```

If the user types a path that does not exist or is not in Done status, ask again. Do not proceed.

Carry the chosen `<source_spec_path>` into all subsequent steps.

## Step 2: Scan and bucket plan-progress files

Read every `docs/superpowers/brainstorms/*-plan-progress.md` and parse out `Status` and `Source Spec` from each.

Bucket as follows:
- In Progress
- Done — same spec
- Done — other spec (cross-borrowing reference only)
- Abandoned — same spec
- Abandoned — other spec

## Step 3: Menu

```
docs/superpowers/brainstorms/ plan-progress for Source Spec = <chosen path>:

In Progress (N):
  [1] <date>-<slug>-plan-progress.md
      Current Phase: <phase>
      Last Updated: <timestamp>
  [2] ...

Done — same spec (M):
  [d1] <date>-<slug>-plan-progress.md
  ...

Done — other spec, for borrowing reference only (K, most recent 5):
  [d3] <date>-<slug>-plan-progress.md — Source Spec: <other-spec>
  ...

Abandoned — same spec (P):
  [a1] ...

Abandoned — other spec (Q):
  [a3] ...

Please choose:
  A) Continue an In Progress session (recommended; precise recovery via Current Phase) → "<number>"
  B) Start a new session based on a Done                                                → "new based on <id>"
  C) Start a new session based on an Abandoned                                          → "new based on <id>"
  D) Abandon an In Progress session                                                      → "abandon <number>"
```

Apply the same omission rules as `resume-brainstorming` (skip absent buckets). If all buckets are empty after omission, bypass the menu and return `proceed-with-new-empty` along with the source spec path; the writing-plans SKILL then creates a fresh plan-progress file from the template and writes the source-spec metadata into it.

## Acting on the user's choice

### A — Continue In Progress

1. Read the chosen file in full.
2. Return: file path + parsed `Current Phase` to the writing-plans SKILL.

### B — Start new, based on a Done

1. Read the Done file in full.
2. Create `docs/superpowers/brainstorms/<today>-<slug>-plan-progress.md` from the template, set `Source Spec: <chosen path>` and `Based On: <Done filename>`.
3. Inject the Done file's full content as context for the writing-plans SKILL to begin draft writing from.
4. Return: new file path, `Current Phase: draft_writing`, plus the prior file content as context.

### C — Start new, based on an Abandoned

Same as B, surfacing the abandonment rationale (if present) as additional context.

### D — Abandon an In Progress

Same procedure as `resume-brainstorming` option D: set `Status: Abandoned`, append an Abandonment section, commit, re-run this SKILL.

## Current Phase precise recovery (for option A)

| Current Phase | Resume behaviour |
|---|---|
| `draft_writing` | Read the source spec and any prior writing notes. Continue from the draft on disk. |
| `review_round_N` | Re-dispatch round N's reviewers (draft is in the working directory, unchanged because mid-loop commits never happen). |
| `awaiting_user_decision` | Re-present the open `I<n>` block(s) to the user. |
| `finalizing` | Re-present the converged plan for final sign-off. |

## What this SKILL does NOT do

- It does not modify the chosen file (except option D's abandonment edit).
- It does not start the writing-plans flow itself.
- It does not commit anything except in option D.
- It does not auto-decide; the user always picks from the menu (and always picks the source spec first).

## File referenced

- `./templates/plan-progress-template.md` — the verbatim template used when creating new files.
