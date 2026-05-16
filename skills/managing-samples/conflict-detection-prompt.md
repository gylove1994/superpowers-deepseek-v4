# Conflict Detection Prompt

This prompt is used by the `managing-samples` SKILL to detect duplicate or conflicting samples before a new sample is added to the library.

## When to use

- **Single promotion**: scan the candidate new entry against every existing entry in the target INDEX (specs or plans).
- **Initialization**: do an N×N scan across all candidate entries that are being seeded together, returning all conflict pairs in one report.

## Input

You will receive:
- `existing_entries` — all current YAML entries from the target INDEX (`samples/specs/INDEX.md` or `samples/plans/INDEX.md`).
- `new_entries` — one or more candidate YAML entries to be evaluated.

## Task

For every pair (existing_i, new_j) — and additionally for every pair (new_i, new_j) when called in initialization mode — classify into one of three categories:

1. **DUPLICATE** — Same `domain` AND highly similar `characteristics` AND highly similar `problem_summary`. Treat as the same sample at different stages of polish; only one should exist.
2. **CONFLICT** — Similar `problem_summary` (same problem domain and intent) but `characteristics` indicate opposing methods. Reviewer agents using either as a basis would receive contradictory guidance.
3. **NONE** — Neither duplicate nor conflict. Both can coexist.

Be conservative: when in doubt, classify as NONE. False positives waste the user's time.

## Output format

Return YAML in this exact shape:

```yaml
pairs:
  - left: <filename of entry A>
    right: <filename of entry B>
    relation: DUPLICATE | CONFLICT
    rationale: <one-sentence justification citing the specific overlap or contradiction>
  - ...
```

If no conflicts or duplicates are found, return:

```yaml
pairs: []
```

## Rationale style

- For DUPLICATE: name the overlapping fields. Example: "Both target hook design with characteristics 'pre-commit verification' and identical problem_summary."
- For CONFLICT: name the opposing methods. Example: "Both solve worktree management but A uses native-tool-first detection while B mandates explicit user choice — reviewers basing on each would push the draft in opposite directions."

## Three-way user resolution (handled by SKILL, not this prompt)

After this prompt returns its `pairs`, the SKILL will present each pair to the user with three options:
- Keep new, delete old
- Keep old, abandon new
- Keep both (user judges them not actually in conflict)
