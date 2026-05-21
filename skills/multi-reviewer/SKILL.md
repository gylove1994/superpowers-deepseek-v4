---
name: multi-reviewer
description: Use to run a multi-round review loop on a spec or plan draft. Dispatches 6 fixed reviewers (architect, red-team, edge-cases, yagni-gatekeeper, bdd-reviewer, tdd-reviewer) plus up to 2 exemplar-matchers (one per matched sample), then an arbiter that filters and arbitrates. Loop converges, degenerates, or hits a 3-round ceiling.
---

# Multi-Reviewer Subsystem

## When to invoke

This SKILL is invoked by:
- The refactored `brainstorming` SKILL after its Phase B draft is written.
- The refactored `writing-plans` SKILL after its plan draft is written.

It is not invoked by the user directly.

**Announce at start:** "I'm using the multi-reviewer subsystem to run round N of review."

## What you (the main flow agent) must do

You play two roles during this loop:
- **Controller** — Dispatch reviewer and arbiter subagents, collect outputs, update the decision-log / plan-progress file.
- **DS** — When the arbiter returns `CONTINUE`, you revise the draft.

Subagents have isolated contexts and do not see your conversation history.

## The loop

Implements the pseudocode in `convergence-rules.md`. Each iteration:

### 1. Compute reviewer dispatch list

- Always include: `architect`, `red-team`, `edge-cases`, `yagni-gatekeeper`, `bdd-reviewer`, `tdd-reviewer`.
- Plus: one `exemplar-matcher` per matched sample (0, 1, or 2). Total reviewer count is 6, 7, or 8.

### 2. Update the decision-log / plan-progress file

Before dispatching, in the file's "Round N" subsection, write:
- Dispatched reviewers list (with sample assignment for exemplar-matchers).
- Receipt status table: all reviewers as `⏳ waiting`.

(The file path is provided to you by the calling SKILL — either a `*-brainstorm.md` for brainstorming Phase B, or a `*-plan-progress.md` for writing-plans.)

### 3. Dispatch all reviewers in parallel

Issue all N reviewer Task invocations in the same message batch. Each invocation gets:
- The reviewer prompt from `reviewer-prompts/<role>.md`.
- The current draft (full text).
- The reviewer's `reviewer_role`.
- For exemplar-matcher only: the assigned sample's filename + full content.
- **document_type selection:** brainstorming Phase B → `spec-draft`; writing-plans → `plan-draft`. Invalid or missing enum → receipt ✗ failed (re-dispatch once, then exclude per §4).
- Preamble for every reviewer: `document_type` as above.
- For `bdd-reviewer` on plan-draft: include `source_spec_path` + full source spec text.
- For `tdd-reviewer` on plan-draft: include `source_spec_path` + full source spec `## Testing Strategy` section text; if section absent, pass `testing_strategy_absent: true` and tdd-reviewer applies spec §C.1 BLOCKING against source spec.
- Load prompts from `reviewer-prompts/bdd-reviewer.md` and `reviewer-prompts/tdd-reviewer.md`.

### 4. Collect and validate receipts

For each reviewer output:
1. Validate YAML finding-schema (all required fields; empty findings require `NO_BLOCKING_ISSUES: true`).
2. If invalid, empty, non-YAML, or crash → re-dispatch once with format reminder.
3. Second failure → mark receipt `✗ failed`, exclude from arbiter input, record in decision-log.
4. Valid → mark `✓`.

Record in Round N metadata: `dispatched_count`, `successful_receipt_count`, `excluded_roles`.

If **all** reviewers failed: do not dispatch arbiter; mark round failed; surface to user.

If any fixed reviewer role is in `excluded_roles`: arbiter must not return `STOP_CONVERGED` unless user-arbitration accepts partial round.

As each reviewer returns, update the receipt status in the file (`⏳ → ✓` or `✗ failed`) and append its raw findings (with `arbiter_status` initially blank) to the round's Findings table.

### 5. Dispatch the arbiter

After receipt validation completes (not merely when subagents return):
- Build `reviewer_outputs` from receipts marked ✓ only.
- If `successful_receipt_count == 0`, skip arbiter; mark round failed in decision-log.
- Dispatch arbiter with: draft, filtered reviewer_outputs, round, prev_total, and round_metadata `{ dispatched_count, successful_receipt_count, excluded_roles }`.
- If any fixed reviewer is in `excluded_roles`, arbiter must not emit STOP_CONVERGED unless decision-log records explicit user acceptance of partial review.

### 6. Process arbiter output

Read the arbiter's YAML output. Update the decision-log / plan-progress file:
- Fill `Arbiter` column for every finding (KEEP / MERGED into X / DEDUP_DISCARDED / FALSE_DISCARDED / APPENDIX).
- Append the "Arbiter Output" block with counts, degradation_check, convergence_status, and arbiter_rationale.
- Append the `findings_appendix` items as a separate "Appendix (NITs)" subsection.

Then branch on `convergence_status`:

| Status | Action |
|---|---|
| `STOP_CONVERGED` | Exit the loop. The draft is accepted. Update `Current Phase` (in brainstorming) to `finalizing`. |
| `STOP_DEGENERATE` | Exit the loop. Enter user-arbitration handoff (see `convergence-rules.md` §User arbitration handoff). |
| `STOP_LIMIT` | Same as STOP_DEGENERATE: enter user-arbitration handoff. |
| `CONTINUE` | Revise the draft per `revision_instructions`, update each finding's `Status` column from `⏳ PENDING` to `✓ FIXED`, then go to step 1 with round = round + 1. |

### 7. User-arbitration handoff (only on degenerate or limit)

For each unresolved finding from the arbiter's `revision_instructions`, present three options to the user:
- **Accept and fix** — you revise immediately; the finding's Status becomes `✓ FIXED`.
- **Reject** — record a new user-intervention block `I<n>` in the decision-log / plan-progress file (per the file's "User Intervention Decisions" section), with the rationale the user provides. Update the finding's Status to `✗ USER_REJECTED(I<n>)`.
- **Defer** — leave the finding open. Update Status to `USER_DEFERRED`.

After all unresolved findings have a user decision, either re-enter the loop (if the user wants another round after fixes) or proceed to the calling SKILL's finalization step.

## Important constraints

- **Do not commit during the loop.** All file updates stay in the working directory. The calling SKILL commits at terminal Status only.
- **Do not skip the file updates.** The decision-log / plan-progress file is the single source of truth; if you forget to update it, the user loses visibility and resume becomes broken.
- **Do not dispatch reviewers serially.** Always issue the batch in parallel.
- **Do not invent reviewer findings.** You only collect, arbitrate, and revise.

## Files referenced

- `./finding-schema.md` — what every reviewer produces.
- `./convergence-rules.md` — the loop, the four terminal states, the user-arbitration handoff.
- `./arbiter-prompt.md` — what the arbiter does.
- `./reviewer-prompts/architect.md`
- `./reviewer-prompts/red-team.md`
- `./reviewer-prompts/edge-cases.md`
- `./reviewer-prompts/yagni-gatekeeper.md`
- `./reviewer-prompts/exemplar-matcher.md`
- `./reviewer-prompts/bdd-reviewer.md`
- `./reviewer-prompts/tdd-reviewer.md`
