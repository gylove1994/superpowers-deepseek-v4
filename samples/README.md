# Exemplar Samples Library

This library holds high-quality spec and plan exemplars. They are used in two places by the deepseek-v4-pro optimization flow:

1. **At draft time**: When `brainstorming` (Phase B) or `writing-plans` starts writing a spec/plan draft, the main flow agent reads `specs/INDEX.md` (or `plans/INDEX.md`), matches the current task against the metadata of each entry, and injects up to 2 most relevant samples into its context as references for structure, rigor, and style.

2. **At review time**: Each injected sample also spawns one dedicated "exemplar-matcher" reviewer subagent. That reviewer compares the draft against its assigned sample and flags structural completeness gaps or missing sections.

## Directory layout

- `specs/` — exemplar spec documents and their `INDEX.md`
- `plans/` — exemplar plan documents and their `INDEX.md`

## How samples enter this library

Samples are only added or removed when the user explicitly requests it. The `skills/managing-samples/` SKILL handles two flows:

- **Initialization** (one-time): seed the library from existing `docs/superpowers/specs/` and `docs/superpowers/plans/`.
- **Single promotion** (any time): user says "add file X as exemplar" and the SKILL processes one file.

The main flow agent never auto-asks "should I add this as a sample" and never auto-recommends additions. Sample curation is always user-driven.

## Matching at runtime

When the main flow agent needs to find matching samples for the current task:
1. Read `<this dir>/specs/INDEX.md` (or `plans/INDEX.md`).
2. For each entry's metadata (`topic`, `domain`, `scale`, `characteristics`, `problem_summary`), semantically compare against the current user request.
3. Select the most relevant samples; cap at 2.
4. Report the choice to the user: "Selected X, Y as references because ...". Default to proceeding; user may override.
5. If zero matches, proceed without samples. The `exemplar-matcher` reviewer is then not dispatched (6 fixed reviewers participate; total 6 instead of 7–8).

## Sample file format

Files are stored verbatim as copies of the original spec/plan documents — no sanitization. Real-world project paths and decisions are part of the educational value.

## Conflict policy

Two samples must not contradict each other (same problem, opposite methods). The `managing-samples` SKILL runs a conflict scan whenever samples are added; conflicting pairs are surfaced to the user for resolution.
