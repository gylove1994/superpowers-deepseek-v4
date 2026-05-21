# Finding Schema

Every reviewer in the `multi-reviewer` subsystem produces zero or more findings using this schema. The arbiter consumes them, deduplicates, filters, and produces revision instructions for the main flow agent.

## Required schema per finding

```yaml
severity: BLOCKING | IMPORTANT | NIT
location: <section heading or quoted phrase from the draft>
problem: <one-sentence problem statement>
evidence: <why this is a problem — may quote the draft, cite the spec, cite an exemplar sample, or describe a failing scenario>
suggestion: <minimal modification to fix it>
reviewer_role: architect | red-team | edge-cases | yagni-gatekeeper | exemplar-matcher | bdd-reviewer | tdd-reviewer
```

**Every field is required.** Findings missing any field are discarded by the arbiter (`FALSE_DISCARDED`).

## Severity definitions

- **BLOCKING** — The draft is incorrect, contradictory, or unimplementable if this is not fixed. Without resolution the spec/plan cannot proceed.
- **IMPORTANT** — The draft will produce a measurably worse outcome (lower quality, larger scope, missed coverage, ambiguous interpretation) if not addressed.
- **NIT** — Style, wording, or personal preference. Does not block convergence. Capped at 3 per reviewer per round; further NITs are dropped at the reviewer level.

## Output format per reviewer

Each reviewer produces a YAML block:

```yaml
findings:
  - severity: BLOCKING
    location: "§Design / Task 2"
    problem: "Task 2 has no acceptance criterion."
    evidence: "Spec §2.3 requires every task to declare a measurable acceptance criterion. Task 2's 'Step 5: Commit' is the only criterion shown, which is process, not outcome."
    suggestion: "Add an explicit acceptance criterion such as 'Run X; expected output Y' before the commit step."
    reviewer_role: architect
  - ...
```

If a reviewer finds zero blocking or important issues, it must still produce a valid YAML output:

```yaml
findings: []
NO_BLOCKING_ISSUES: true
```

This explicit acknowledgement (rather than an empty response) is required so the arbiter can distinguish "reviewer ran and found nothing" from "reviewer crashed or returned nothing".

## Reviewer prompts must enforce

The seven reviewer prompt files (`reviewer-prompts/*.md`) each spell out:
- The reviewer's role boundary (what it must look at; what it must not look at).
- An explicit NIT cap of 3 per round.
- The exact YAML output format above.
- The requirement to emit `NO_BLOCKING_ISSUES: true` when nothing critical is found.
- A ban on findings that are merely style preferences or that lack evidence.

## Finding ID convention

Findings do not carry IDs at the reviewer level. The arbiter assigns IDs in the form `F<round>.<index>` (e.g. `F1.3` = third surviving finding of round 1) when writing them into the decision log / plan-progress file.

## Arbiter actions on findings

The arbiter (`arbiter-prompt.md`) processes the union of all reviewer outputs in this order:

1. **Dedup** — Multiple reviewers reporting the same `location + problem` are merged into one finding, with a `reviewers` array. Surviving severity is the highest among the duplicates. The discarded duplicates' status becomes `DEDUP_DISCARDED`.
2. **False discard** — Findings missing any required field, or whose `evidence` is empty / generic ("seems wrong", "feels off"), or whose `suggestion` does not address the stated `problem` → `FALSE_DISCARDED`.
3. **Conflict arbitration** — Two findings proposing opposite changes to the same `location` → arbiter picks one with rationale; the loser is `FALSE_DISCARDED` with rationale recorded.
4. **Severity downgrade** — NITs are not passed to the main flow as revision instructions; they are written to an appendix in the decision-log file with status `APPENDIX`.
5. **Merge** — When findings clearly overlap or one subsumes the other (e.g. "task too coarse" and "task boundary unclear" on the same task), arbiter may set the loser's status to `MERGED into F<x.y>`.

The arbiter then emits its full output per `arbiter-prompt.md`.
