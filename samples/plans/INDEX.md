# Plans Sample Index

Each entry below describes one plan sample in `samples/plans/<filename>.md`. The metadata is used by the main flow agent to match samples against new plan-writing tasks.

## Entry schema

See `skills/managing-samples/index-entry-schema.md` for the authoritative schema. Brief summary:

```yaml
- file: <filename>.md
  topic: <one-sentence subject>
  domain: <category>
  scale: small | medium | large
  characteristics:
    - <distinguishing trait 1>
    - <distinguishing trait 2>
  problem_summary: <one-sentence problem this plan addresses>
  why_exemplar: <what about this sample is worth learning>
```

## Entries

(empty — populated by Task 1.5 of the implementation plan)
