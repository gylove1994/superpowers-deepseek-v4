---
name: managing-samples
description: Use ONLY when the user explicitly asks to initialize the exemplar samples library or to promote a specific spec/plan file as an exemplar. Never auto-trigger; never recommend addition unprompted.
---

# Managing Samples

## When to invoke

This SKILL is **strictly user-driven**. Invoke it only when the user explicitly says one of:

- "Initialize the samples library" / "Seed the samples library" / equivalent
- "Add <file> as a sample" / "Promote <file> as exemplar" / equivalent

Do **not** invoke this SKILL:
- Automatically after a brainstorming or writing-plans session completes
- As a "would you like to save this as a sample?" prompt to the user
- Based on quality heuristics (convergence rounds, finding counts, etc.)

The user owns this library. The agent operates it on request.

## Two workflows

### Workflow 1: Initialization (one-time)

Used when the library is empty and the user wants to seed it from `docs/superpowers/specs/` and `docs/superpowers/plans/`.

1. **Discover** — list all `*.md` files under `docs/superpowers/specs/` and `docs/superpowers/plans/`.
2. **Generate candidate metadata** — for each discovered file, read its contents and produce a candidate YAML entry conforming to `index-entry-schema.md`. Use your judgment on `domain`, `characteristics`, `problem_summary`, `why_exemplar` based on the file's content.
3. **Present for user review** — show all candidate entries in a table. Ask the user to confirm, edit, or skip each entry. Do not proceed until the user has acknowledged every candidate.
4. **Global conflict scan** — invoke the `conflict-detection-prompt.md` in initialization mode (N×N) over all accepted candidates. Collect the `pairs` report.
5. **User batch resolution** — for every reported pair, present the three-way choice (keep new+delete old / keep old+abandon new / keep both). Collect the user's decisions.
6. **Apply decisions** — for each accepted candidate that survives, copy the source file from `docs/superpowers/specs/` or `docs/superpowers/plans/` into the corresponding `samples/specs/` or `samples/plans/` directory (preserve filename), and append its YAML block to the matching `INDEX.md`.
7. **Commit** — `git add samples/ && git commit -m "feat(samples): seed initial sample library"`

### Workflow 2: Single promotion (any time)

Used when the user names a specific file to promote into the library.

1. **Read source file** — load the spec or plan the user named.
2. **Recommend metadata** — produce a candidate YAML entry per `index-entry-schema.md`. Show it to the user; let them edit any field.
3. **Conflict scan** — invoke `conflict-detection-prompt.md` in single-promotion mode: candidate vs. all existing entries in the target `INDEX.md`. Collect the `pairs` report.
4. **Resolve conflicts** — for each reported pair, present the three-way choice. Apply the user's decision (which may involve deleting existing samples + their INDEX entries).
5. **Copy file** — `cp <source-path> samples/specs/<filename>` (or `samples/plans/<filename>`). Preserve filename.
6. **Append INDEX entry** — append the (possibly edited) YAML block to `samples/specs/INDEX.md` or `samples/plans/INDEX.md`.
7. **Commit** — `git add samples/ && git commit -m "feat(samples): add <topic> as exemplar"`

## Validation before commit

Before committing, verify:
- The file referenced by each new entry's `file` field exists on disk in the corresponding samples subdirectory.
- The YAML entry contains all 7 required fields (per `index-entry-schema.md`).
- No remaining unresolved conflict pairs from the scan.

If any validation fails, fix the issue inline and re-validate. Do not commit a half-finished state.

## Conflict resolution outcomes

When the user picks "keep new, delete old":
- Delete the old sample file from `samples/specs/` or `samples/plans/`.
- Remove the old YAML entry from the corresponding `INDEX.md`.
- Add the new entry and copy the new file.

When the user picks "keep old, abandon new":
- Do nothing for the new candidate. Continue to the next candidate (initialization mode) or end the workflow (single promotion mode).

When the user picks "keep both":
- Add the new entry and copy the new file. Old entry remains untouched. User has asserted the two are not actually in conflict.

## Out of scope

This SKILL does not:
- Modify or sanitize sample file contents. Files are copied verbatim.
- Re-evaluate existing samples for quality. Use single promotion to re-add an existing sample only via explicit user request.
- Auto-prune old samples based on age. Pruning is a future concern (Spec B).
