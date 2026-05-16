---
name: writing-plans
description: Use when a Done spec exists and a multi-step implementation plan must be produced. Writes the plan with bite-sized TDD-style tasks, runs the multi-reviewer subsystem until convergence, and tracks the entire spec-to-plan process in a plan-progress file.
---

# Writing Plans

Produce a comprehensive implementation plan from a Done spec. Assume the implementing engineer has zero context for our codebase and questionable taste: spell everything out — files, code, expected output, commits. DRY, YAGNI, TDD, frequent commits.

Track the full spec-to-plan process in a `*-plan-progress.md` file. Mid-process never commits; only `Status: Done` or `Status: Abandoned` commits.

**Announce at start:** "I'm using the writing-plans SKILL."

## Step 0 (strict first step): Invoke resume-planning

Always invoke `superpowers:resume-planning` first. It:
1. Forces selection of a Done source spec.
2. Scans existing plan-progress files for that spec.
3. Returns one of:
   - `proceed-with-new-empty` + source spec path (no existing plan-progress for this spec, or user chose new)
   - A path of an In Progress file to continue (option A)
   - A new file path (Based On a Done or Abandoned plan-progress) plus the prior file's content as context

## Step 1: Initialize the plan-progress file

Use `skills/resume-planning/templates/plan-progress-template.md` as the verbatim base. Fill the metadata header:
- `Date Started: <today>`
- `Status: In Progress`
- `Current Phase: draft_writing`
- `Source Spec: <path from Step 0>`
- `Based On:` (only if resume returned a new-based-on path)
- `Last Updated: <now>`

Populate Context Reference:
- `Source Spec Summary` — extract Problem + Goals (or equivalent) from the source spec.
- `User's Launch Instruction` — the user's message that triggered this writing-plans invocation, verbatim.

## Step 2: Scope check

If the source spec covers multiple independent subsystems, the brainstorming phase should have decomposed it already. If you nonetheless find the spec sprawls into independent areas, push back: suggest splitting into multiple plans — one per subsystem — each producing working, testable software on its own. Record any such decomposition in the plan-progress file (as plain note, not a Q&A — plan-progress has no Q&A section).

## Step 3: Sample matching

Read `samples/plans/INDEX.md`. Semantically match the current task against each entry's metadata.
- Select up to 2 most relevant samples.
- Tell the user: "Selected sample(s) `<filenames>` as references because <reason>. Proceeding."
- If the user objects, accept overrides.
- If 0 samples, record it; the multi-reviewer subsystem runs with 4 reviewers only.

Load the chosen samples' full content into your context.

## Step 4: Write the initial plan draft

Write `docs/superpowers/plans/<today>-<source-spec-slug>.md` from scratch.

The plan must:
- Start with the required header:

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence]

**Architecture:** [2–3 sentences about the approach]

**Tech Stack:** [Key technologies/libraries]

**Spec:** `<path to source spec>`

---
```

- Use the `### Task N: <component>` structure for every task, with:
  - **Files:** list of files to Create / Modify / Delete (exact paths and line ranges where appropriate).
  - Numbered checkbox steps `- [ ] **Step N: <action>**`.
  - For TDD-able code tasks: failing test first, run-to-fail confirmation, minimal implementation, run-to-pass confirmation, commit. Each step is 2–5 minutes of work.
  - For prompt-template / skill-file tasks where TDD does not apply: a structure self-check step in lieu of test step (see Task 1.4 of THIS plan as a model).
  - For each commit step: exact `git add` + commit message with a heredoc.

- **No placeholders.** No "TBD", "implement later", "similar to Task N", "add appropriate error handling". Every step contains the actual content the engineer needs.

After writing, update the plan-progress file: `[✓] Initial draft complete (time: <now>)`. Update `Current Phase: review_round_1`.

## Step 5: Multi-reviewer loop

Invoke `superpowers:multi-reviewer`. Pass:
- The draft (the plan file).
- The matched samples (0–2).
- The plan-progress file path.

When it returns:
- `STOP_CONVERGED` → continue to Step 6.
- `STOP_DEGENERATE` or `STOP_LIMIT` with unresolved → user-arbitration completed within the subsystem; continue to Step 6 once all unresolved findings have a USER_REJECTED / USER_DEFERRED / FIXED disposition.

Update the file: `Current Phase: finalizing`.

## Step 6: Plan self-review (the inline check the agent runs)

Before showing the plan to the user, do a fresh-eyes pass per the prior writing-plans guidelines:
1. **Spec coverage** — for each requirement in the source spec, can you point to a plan task that implements it? If not, add one.
2. **Placeholder scan** — search for TBD, TODO, "implement later", "similar to", undefined types/functions, missing code blocks. Fix inline.
3. **Type consistency** — names, signatures, file paths used in later tasks match what earlier tasks defined.

Fix issues inline.

## Step 7: User sign-off and commit

Show the plan to the user: "Plan written at `<plan path>`. Please review and either approve or request specific changes."

If the user requests changes, revise and re-present (recording the changes in the plan-progress file's Plan Writing Status updates as additional revision rounds).

When the user approves:
1. Update the plan-progress file:
   - `Status: Done`
   - `Current Phase: finalizing` (stays)
   - `Final Plan: <plan path>`
   - `Last Updated: <now>`
2. Commit both the plan and the plan-progress file:
   ```bash
   git add docs/superpowers/plans/<plan-filename>.md docs/superpowers/brainstorms/<plan-progress-filename>.md
   git commit -m "feat(plan): <topic>"
   ```

## Step 8: Execution handoff

Offer the user the execution choice (preserved from previous writing-plans behavior):

> "Plan complete at `<path>`. Two execution options:
>
> **1. Subagent-Driven (recommended)** — fresh subagent per task, two-stage review between tasks, fast iteration.
>
> **2. Inline Execution** — execute tasks in this session using executing-plans, batch execution with checkpoints.
>
> Which approach?"

- If Subagent-Driven → invoke `superpowers:subagent-driven-development`.
- If Inline → invoke `superpowers:executing-plans`.

## Abandonment

Same as brainstorming abandonment: set `Status: Abandoned`, append `## Abandonment` block with timestamp and reason, commit.

## Anti-patterns

- "Skip the multi-reviewer loop for a small plan." No. The loop is the design.
- "Commit each round of revision." No. Mid-process never commits.
- "Use 'similar to Task 1' for repeated patterns." No. Repeat the content; engineers may read tasks out of order.
- "Mark a step as 'add tests for the above' without writing the tests." No. Every step is concrete.

## Files referenced

- `superpowers:resume-planning` (mandatory first step)
- `superpowers:multi-reviewer` (review loop)
- `samples/plans/INDEX.md` and any sample file selected
- `docs/superpowers/brainstorms/<filename>-plan-progress.md` (the progress file)
- `docs/superpowers/plans/<filename>.md` (the produced plan)
- `superpowers:subagent-driven-development` or `superpowers:executing-plans` (execution handoff)
