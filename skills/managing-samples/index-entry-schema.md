# Index Entry Schema

Every sample in `samples/specs/INDEX.md` or `samples/plans/INDEX.md` corresponds to one YAML block conforming to this schema.

## Schema

```yaml
- file: <filename>.md           # required, relative to the INDEX file's directory
  topic: <string>               # required, one-sentence subject
  domain: <string>              # required, category (e.g. "hook design", "skill design", "harness compatibility")
  scale: small | medium | large # required
  characteristics:              # required, 1–5 entries
    - <string>
  problem_summary: <string>     # required, one-sentence statement of what this sample solves
  why_exemplar: <string>        # required, what about this sample is worth learning (structure / rigor / clarity / coverage / etc.)
```

## Field rules

- **file** — must match an actual file in `samples/specs/` or `samples/plans/`. Filename casing matches the file on disk.
- **topic** — one sentence. No trailing period required.
- **domain** — short categorical noun phrase. Reuse existing values where possible to keep matching coherent.
- **scale** — `small` (one component / single-file change), `medium` (multi-file or one subsystem), `large` (cross-cutting or multi-subsystem).
- **characteristics** — distinguishing traits that make this sample useful for matching (e.g. "multi-harness compatible", "git worktree lifecycle"). Avoid generic words like "well-written" — those go in `why_exemplar`.
- **problem_summary** — must complete the sentence "This sample solves the problem of …".
- **why_exemplar** — what an agent should learn or imitate. Examples: "comprehensive Goals/Non-Goals split", "explicit Design Principles section", "tightly-scoped tasks with TDD rhythm".

## Validation

When new entries are appended (by the `managing-samples` SKILL), the SKILL must:
- Verify all required fields are present.
- Verify `file` exists on disk.
- Verify `scale` is one of the three allowed values.
- Reject any entry that fails these checks.
