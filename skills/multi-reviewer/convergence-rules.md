# Convergence Rules

The multi-reviewer subsystem runs reviewer dispatch and arbiter in a loop until one of four terminal states is reached. This file specifies the loop, the terminal states, and the user-arbitration handoff.

## Termination states

| Status | Cause |
|---|---|
| `STOP_CONVERGED` | After arbiter filtering, `BLOCKING + IMPORTANT` count = 0. The draft is accepted. |
| `STOP_DEGENERATE` | The degradation check failed (this round's effective finding count is not ≤ 50% of the previous round's). Reviewers are now manufacturing problems rather than converging. Hand off unresolved items to the user. |
| `STOP_LIMIT` | The hard ceiling of 3 rounds was reached. Hand off unresolved items to the user. |
| `CONTINUE` | None of the above; proceed to next round after the main flow agent applies revisions. |

## The loop

Pseudocode (the main flow agent executes this):

```
ROUND = 1
prev_total = +infinity

LOOP:
  draft = (ROUND == 1) ? initial_draft : revised_draft

  reviewer_outputs = parallel_dispatch(
    draft,
    samples_if_hit,  # 0–2 exemplar samples
    fixed_reviewers={architect, red-team, edge-cases, yagni-gatekeeper, bdd-reviewer, tdd-reviewer},
    exemplar_matchers=one_per_sample
  )

  reviewer_outputs = validate_receipts(raw_outputs)  # re-dispatch once; excluded_roles; ✓ only to arbiter
  if successful_receipt_count == 0: round_failed; continue LOOP or abort
  arbiter_output = arbiter(
    reviewer_outputs=successful_only,
    draft,
    round=ROUND,
    prev_total=prev_total,
    round_metadata={dispatched_count, successful_receipt_count, excluded_roles}
  )

  IF arbiter_output.convergence_status == STOP_CONVERGED:
    BREAK   # accepted

  IF arbiter_output.convergence_status == STOP_DEGENERATE:
    user_arbitration(arbiter_output)
    BREAK

  IF ROUND >= 3:
    arbiter_output.convergence_status = STOP_LIMIT
    user_arbitration(arbiter_output)
    BREAK

  revised_draft = main_flow_agent.revise(draft, arbiter_output.revision_instructions)
  prev_total = arbiter_output.counts.blocking + arbiter_output.counts.important
  ROUND += 1
```

## Degradation check (the anti-rationalization gate)

Without this gate, reviewers will perpetually find new things to complain about and the loop will never converge. The check:

- **Round 1**: degradation_check = `N/A` (no baseline yet).
- **Round N ≥ 2**: arbiter computes `current_effective = blocking + important` of this round. If `current_effective > 0.5 * prev_total`, the degradation_check is `FAILED` and convergence_status becomes `STOP_DEGENERATE`. Otherwise `PASSED`.

Tuning: 0.5 is the chosen threshold (50% reduction required per round). It is not adjustable per-session — adjust here if the entire fork's experience justifies it.

## Hard ceiling

After round 3, even if degradation is still passing, the loop stops with `STOP_LIMIT`. Three rounds × six-to-eight parallel reviewers is the cost budget; further rounds rarely yield meaningful changes.

## STOP_CONVERGED guards

- If `successful_receipt_count == 0` for a round, do not call arbiter; round status = failed.
- If any fixed reviewer role is in `excluded_roles` for this round, arbiter must not emit `STOP_CONVERGED` unless the decision-log records explicit user acceptance of partial review.
- Invalid `document_type` → receipt ✗ failed; re-dispatch once with valid enum; second failure → exclude per malformed path.

## User arbitration handoff

When the loop terminates with `STOP_DEGENERATE` or `STOP_LIMIT` and `unresolved` is non-empty, the main flow agent must:

1. Present a convergence report to the user, structured as:
   - Status: STOP_DEGENERATE or STOP_LIMIT (with brief reason)
   - Round-by-round counts
   - All unresolved BLOCKING and IMPORTANT findings with arbiter rationale
2. For each unresolved finding, offer three choices:
   - **Accept and fix** — main flow agent revises the draft to address it, then loops back to a fresh round 1 (resetting the round counter) or to commit-as-final, per user's preference
   - **Reject** — record the rejection rationale; the finding's status becomes `USER_REJECTED(I<n>)` in the decision-log / plan-progress file. A new user-intervention block `I<n>` is recorded
   - **Defer** — leave the finding open; finalize the draft anyway. The decision log records `USER_DEFERRED`
3. After all unresolved findings have a user decision, either re-enter the loop (if any "Accept and fix" was chosen, at user's discretion) or proceed to finalization (`finalizing` Phase).

## What "parallel" means

The main flow agent's reviewer dispatch is parallel by way of issuing N independent subagent invocations (Task tool) in the same message batch. Each subagent receives its prompt + the draft + (if it is an exemplar-matcher) the one specific sample it is assigned. Subagent contexts are fully isolated; no reviewer sees another reviewer's output.

After all reviewer subagents return, the arbiter is a sixth (or further) subagent dispatch, receiving the assembled raw outputs + the draft + current round + prev_total.

## What "revise" means

The main flow agent acts as ds for the revision step. It reads the arbiter's `revision_instructions` list (each instruction is `{finding_id, action_required}`) and applies them to the draft. The draft remains in the working directory (no commit). The plan-progress / decision-log file's finding table updates each row's Status field accordingly (`PENDING → FIXED`, or `PENDING → USER_REJECTED(I<n>)` if the user later rejects it via arbitration).
