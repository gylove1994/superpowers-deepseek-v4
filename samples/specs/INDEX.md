# Specs Sample Index

Each entry below describes one spec sample in `samples/specs/<filename>.md`. The metadata is used by the main flow agent to match samples against new spec-writing tasks.

## Entry schema

See `skills/managing-samples/index-entry-schema.md` for the authoritative schema. Brief summary:

```yaml
- file: <filename>.md
  topic: <one-sentence subject>
  domain: <category, e.g. "hook design" / "skill design" / "harness compatibility">
  scale: small | medium | large
  characteristics:
    - <distinguishing trait 1>
    - <distinguishing trait 2>
  problem_summary: <one-sentence problem this spec solves>
  why_exemplar: <what about this sample is worth learning — structure? rigor? clarity?>
```

## Entries

(empty — populated by Task 1.5 of the implementation plan)
