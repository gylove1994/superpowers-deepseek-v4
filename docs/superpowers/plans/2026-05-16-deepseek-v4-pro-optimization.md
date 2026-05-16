# DeepSeek-V4-Pro Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add multi-reviewer review subsystem, exemplar samples library, decision log / plan-progress tracking, and resume SKILLs to this fork; rewrite `brainstorming` and `writing-plans` to integrate them. Target: stabilize ds-v4-pro's spec/plan quality and avoid single-context blind spots.

**Architecture:** Pure prompt-template system, no executable code. Five new SKILL packages (`multi-reviewer/`, `managing-samples/`, `resume-brainstorming/`, `resume-planning/`, plus refactored `brainstorming/` and `writing-plans/`). Reviewer subagents run with isolated context via Task tool; arbiter subagent filters/dedupes/arbitrates; main flow agent acts as both controller and ds (draft author/reviser). Decision logs and plan-progress files are the single source of truth — mid-process never commits, only Status terminal state commits.

**Tech Stack:** Markdown (SKILL files, prompt templates, decision logs, plan-progress), YAML (schemas, finding records), git (versioning final artifacts only). All SKILL files and prompt templates in English. Spec content and decision-log Q&A content can be in any language.

**Spec:** `docs/superpowers/specs/2026-05-16-deepseek-v4-pro-optimization-design.md`

---

## File Structure Overview

Files this plan creates/modifies/deletes (grouped by phase):

### Phase 1 — Infrastructure
- Create: `samples/README.md`
- Create: `samples/specs/INDEX.md`
- Create: `samples/plans/INDEX.md`
- Create (via Task 1.5 seeding): `samples/specs/<5 existing spec files>`
- Create (via Task 1.5 seeding): `samples/plans/<5 existing plan files>`
- Create: `skills/managing-samples/index-entry-schema.md`
- Create: `skills/managing-samples/conflict-detection-prompt.md`
- Create: `skills/managing-samples/SKILL.md`
- Create: `skills/multi-reviewer/finding-schema.md`
- Create: `skills/multi-reviewer/convergence-rules.md`
- Create: `skills/multi-reviewer/arbiter-prompt.md`
- Create: `skills/multi-reviewer/reviewer-prompts/architect.md`
- Create: `skills/multi-reviewer/reviewer-prompts/red-team.md`
- Create: `skills/multi-reviewer/reviewer-prompts/edge-cases.md`
- Create: `skills/multi-reviewer/reviewer-prompts/yagni-gatekeeper.md`
- Create: `skills/multi-reviewer/reviewer-prompts/exemplar-matcher.md`
- Create: `skills/multi-reviewer/SKILL.md`

### Phase 2 — Resume SKILLs and templates
- Create: `docs/superpowers/brainstorms/.gitkeep`
- Create: `skills/resume-brainstorming/templates/brainstorm-template.md`
- Create: `skills/resume-brainstorming/SKILL.md`
- Create: `skills/resume-planning/templates/plan-progress-template.md`
- Create: `skills/resume-planning/SKILL.md`

### Phase 3 — Refactor brainstorming
- Modify (full rewrite): `skills/brainstorming/SKILL.md`
- Delete: `skills/brainstorming/spec-document-reviewer-prompt.md`

### Phase 4 — Refactor writing-plans
- Modify (full rewrite): `skills/writing-plans/SKILL.md`
- Delete: `skills/writing-plans/plan-document-reviewer-prompt.md`

### Phase 5 — End-to-end validation
No file modifications; runs behavior test scenarios and dogfooding.

---

## Phase 1: Infrastructure (Samples Library + Multi-Reviewer Subsystem)

### Task 1.1: Create samples library skeleton

Set up the empty samples directory hierarchy with explanatory README and INDEX placeholders. These index files will be populated in Task 1.5 (seeding).

**Files:**
- Create: `samples/README.md`
- Create: `samples/specs/INDEX.md`
- Create: `samples/plans/INDEX.md`

- [ ] **Step 1: Write `samples/README.md`**

```markdown
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
5. If zero matches, proceed without samples. The `exemplar-matcher` reviewer is then not dispatched (only 4 reviewers participate instead of 5–6).

## Sample file format

Files are stored verbatim as copies of the original spec/plan documents — no sanitization. Real-world project paths and decisions are part of the educational value.

## Conflict policy

Two samples must not contradict each other (same problem, opposite methods). The `managing-samples` SKILL runs a conflict scan whenever samples are added; conflicting pairs are surfaced to the user for resolution.
```

- [ ] **Step 2: Write `samples/specs/INDEX.md`**

```markdown
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
```

- [ ] **Step 3: Write `samples/plans/INDEX.md`**

```markdown
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
```

- [ ] **Step 4: Verify directory layout**

Run: `ls -R samples/`
Expected output should show:
```
samples/:
README.md  plans  specs

samples/plans:
INDEX.md

samples/specs:
INDEX.md
```

- [ ] **Step 5: Commit**

```bash
git add samples/
git commit -m "feat(samples): bootstrap library skeleton

Create samples/{README,specs/INDEX,plans/INDEX}.md as the empty
shell of the exemplar samples library. Actual sample files and
INDEX entries are populated by the managing-samples SKILL in
Task 1.5."
```

---

### Task 1.2: Create `index-entry-schema.md`

Authoritative schema for INDEX entries. Referenced by `managing-samples/SKILL.md` and by both `samples/specs/INDEX.md` and `samples/plans/INDEX.md`.

**Files:**
- Create: `skills/managing-samples/index-entry-schema.md`

- [ ] **Step 1: Create the file**

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add skills/managing-samples/index-entry-schema.md
git commit -m "feat(managing-samples): add index entry schema

Authoritative schema document defining the 7 required fields
for each entry in samples/specs/INDEX.md and samples/plans/INDEX.md."
```

---

### Task 1.3: Create `conflict-detection-prompt.md`

The prompt used by `managing-samples` when scanning for duplicate or conflicting samples before adding a new one.

**Files:**
- Create: `skills/managing-samples/conflict-detection-prompt.md`

- [ ] **Step 1: Create the file**

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add skills/managing-samples/conflict-detection-prompt.md
git commit -m "feat(managing-samples): add conflict detection prompt

Prompt template used to classify pairs of sample candidates as
DUPLICATE / CONFLICT / NONE. The managing-samples SKILL then
presents conflicts to the user for resolution."
```

---

### Task 1.4: Create `managing-samples/SKILL.md`

The user-facing SKILL that wires together the schema and conflict-detection prompt into the two workflows (initialization and single promotion).

**Files:**
- Create: `skills/managing-samples/SKILL.md`

- [ ] **Step 1: Create the file**

```markdown
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
```

- [ ] **Step 2: Self-check structure**

Verify the SKILL.md contains:
- Frontmatter with `name` and `description`
- Clear "When to invoke" gate (user-driven only)
- Both workflows fully spelled out (init + single promotion)
- Validation requirements
- Conflict resolution semantics for all three choices

- [ ] **Step 3: Commit**

```bash
git add skills/managing-samples/SKILL.md
git commit -m "feat(managing-samples): add SKILL.md

User-driven SKILL with two workflows (initialization and single
promotion). Includes validation, conflict resolution semantics,
and explicit non-auto-trigger gate."
```

---

### Task 1.5: Seed the sample library using `managing-samples`

This task **uses** `managing-samples` (now available) to copy the 5 existing specs and 5 existing plans into the samples library and populate the two INDEX files.

**Files affected:**
- Read: `docs/superpowers/specs/*.md` (5 files)
- Read: `docs/superpowers/plans/*.md` (5 files)
- Create: `samples/specs/<5 files>`
- Create: `samples/plans/<5 files>`
- Modify: `samples/specs/INDEX.md`
- Modify: `samples/plans/INDEX.md`

- [ ] **Step 1: Invoke `managing-samples` in initialization mode**

In the working session, say to the agent: "Initialize the samples library."

The agent must follow `skills/managing-samples/SKILL.md` Workflow 1 exactly:
1. List the 5 specs and 5 plans
2. Generate candidate YAML entries
3. Present them for user review and acknowledgment
4. Run the global N×N conflict scan
5. Present any conflict pairs for resolution
6. Apply decisions, copy files, append INDEX entries
7. Commit

- [ ] **Step 2: Verify file count**

Run: `ls samples/specs/*.md | wc -l && ls samples/plans/*.md | wc -l`
Expected: `5` then `5` (or whatever count survives conflict resolution; document the actual numbers in the commit message in Step 1).

- [ ] **Step 3: Verify INDEX coverage**

Run: `grep -c '^- file:' samples/specs/INDEX.md && grep -c '^- file:' samples/plans/INDEX.md`
Expected: matches the file counts from Step 2.

- [ ] **Step 4: Verify commit was made by managing-samples**

Run: `git log --oneline -1`
Expected: `feat(samples): seed initial sample library` (or similar message produced by the SKILL).

No separate commit needed here; the SKILL itself committed in its Workflow Step 7.

---

### Task 1.6: Create `multi-reviewer/finding-schema.md`

Authoritative schema for review findings. Every reviewer in the subsystem produces findings conforming to this schema; the arbiter consumes them.

**Files:**
- Create: `skills/multi-reviewer/finding-schema.md`

- [ ] **Step 1: Create the file**

```markdown
# Finding Schema

Every reviewer in the `multi-reviewer` subsystem produces zero or more findings using this schema. The arbiter consumes them, deduplicates, filters, and produces revision instructions for the main flow agent.

## Required schema per finding

```yaml
severity: BLOCKING | IMPORTANT | NIT
location: <section heading or quoted phrase from the draft>
problem: <one-sentence problem statement>
evidence: <why this is a problem — may quote the draft, cite the spec, cite an exemplar sample, or describe a failing scenario>
suggestion: <minimal modification to fix it>
reviewer_role: architect | red-team | edge-cases | yagni-gatekeeper | exemplar-matcher
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

The five reviewer prompt files (`reviewer-prompts/*.md`) each spell out:
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
```

- [ ] **Step 2: Commit**

```bash
git add skills/multi-reviewer/finding-schema.md
git commit -m "feat(multi-reviewer): add finding schema

Authoritative schema for every review finding. Specifies the 6
required fields, three severity levels with definitions, the
NO_BLOCKING_ISSUES output for empty reviewers, the F<round>.<idx>
ID convention, and the arbiter's actions (DEDUP / FALSE_DISCARDED /
conflict arbitration / NIT downgrade / MERGE)."
```

---

### Task 1.7: Create `multi-reviewer/convergence-rules.md`

Specifies the 5-layer convergence machine that wraps reviewer + arbiter into a self-terminating loop.

**Files:**
- Create: `skills/multi-reviewer/convergence-rules.md`

- [ ] **Step 1: Create the file**

```markdown
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
    fixed_reviewers={architect, red-team, edge-cases, yagni-gatekeeper},
    exemplar_matchers=one_per_sample
  )

  arbiter_output = arbiter(
    reviewer_outputs,
    draft,
    round=ROUND,
    prev_total=prev_total
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

After round 3, even if degradation is still passing, the loop stops with `STOP_LIMIT`. Three rounds × five-ish reviewers is the cost budget; further rounds rarely yield meaningful changes.

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
```

- [ ] **Step 2: Commit**

```bash
git add skills/multi-reviewer/convergence-rules.md
git commit -m "feat(multi-reviewer): add convergence rules

5-layer convergence machine: STOP_CONVERGED / STOP_DEGENERATE /
STOP_LIMIT / CONTINUE. Includes 50% degradation gate, 3-round
hard ceiling, parallel reviewer dispatch semantics, and the
user-arbitration handoff (Accept and fix / Reject / Defer)."
```

---

### Task 1.8: Create `multi-reviewer/arbiter-prompt.md`

The prompt used to dispatch the arbiter subagent. Consumes all reviewer outputs, applies the five processing steps, and emits convergence_status + revision_instructions.

**Files:**
- Create: `skills/multi-reviewer/arbiter-prompt.md`

- [ ] **Step 1: Create the file**

```markdown
# Arbiter Prompt

You are the arbiter for the multi-reviewer subsystem. You receive the raw outputs of all reviewers for one round, plus the draft and round metadata, and you produce a single authoritative output that filters, dedupes, arbitrates conflicts, and decides whether the loop continues.

## Inputs you receive

- `draft` — the full text of the spec or plan draft being reviewed in this round.
- `reviewer_outputs` — a list of reviewer outputs. Each entry has:
  - `reviewer_role` (one of architect | red-team | edge-cases | yagni-gatekeeper | exemplar-matcher)
  - `assigned_sample` (only for exemplar-matcher; identifies which sample this matcher was paired with)
  - `findings` (list of finding objects per `finding-schema.md`) or `NO_BLOCKING_ISSUES: true`
- `round` — the current round number (1 to 3).
- `prev_total` — the total `BLOCKING + IMPORTANT` count from the previous round's arbiter output. `+infinity` for round 1.

## Processing pipeline

Execute these five steps in order. Each step is mandatory.

### Step 1 — Dedup

Group findings whose `location` and `problem` substantially match. For each group of size > 1:
- Keep one canonical finding. Its `severity` is the maximum severity in the group (BLOCKING > IMPORTANT > NIT).
- The canonical finding gains an additional field `reviewers: [<list of reviewer roles>]`.
- Other members of the group get arbiter_status = `DEDUP_DISCARDED` with a note pointing to the canonical finding's ID.

### Step 2 — False discard

For every remaining finding, apply these reject rules:
- Missing any required field per `finding-schema.md` → `FALSE_DISCARDED`.
- `evidence` is empty, or is generic without specifics ("feels off", "seems wrong", "may be confusing") → `FALSE_DISCARDED`.
- `suggestion` does not address the stated `problem` (e.g. problem says "missing test"; suggestion says "rename function") → `FALSE_DISCARDED`.
- Reviewer is `exemplar-matcher` AND `evidence` does not cite a specific section of the assigned sample → `FALSE_DISCARDED`.

### Step 3 — Conflict arbitration

For pairs of findings proposing opposite changes to the same `location` (e.g. "add field X" vs "remove field X"), pick the better one. Record your decision:
- Survivor: `arbiter_status = KEEP` with `arbiter_rationale = "Chosen over <other finding ID> because <reason>"`.
- Loser: `arbiter_status = FALSE_DISCARDED` with `arbiter_rationale = "Lost arbitration to <survivor ID>: <reason>"`.

When choosing, weight by: alignment with the spec's stated Goals and Non-Goals; consistency with established Design Principles; severity (BLOCKING beats IMPORTANT).

### Step 4 — Severity downgrade

NITs (severity = NIT) are not part of the revision instructions. Their arbiter_status becomes `APPENDIX`. They are listed in the appendix of the decision-log / plan-progress file but do not block convergence.

### Step 5 — Merge

For pairs of findings on the same `location` where one subsumes or strictly contains the other, merge:
- Survivor: gains a note "subsumes <other finding ID>" in `arbiter_rationale`.
- Loser: `arbiter_status = MERGED into <survivor ID>`.

After all five steps, every finding has an `arbiter_status` field, every surviving finding is the kind that will be passed to the main flow agent as a revision instruction (unless it is APPENDIX).

## Convergence decision

Compute:
- `blocking_count` = number of surviving findings with severity BLOCKING.
- `important_count` = number of surviving findings with severity IMPORTANT.
- `nit_count` = number of findings with arbiter_status = APPENDIX.
- `current_effective` = blocking_count + important_count.

Decide `convergence_status`:
- If `current_effective == 0` → `STOP_CONVERGED`. The draft is accepted.
- Else if `round >= 2` and `current_effective > 0.5 * prev_total` → `STOP_DEGENERATE`. Reviewers are not converging.
- Else if `round >= 3` → `STOP_LIMIT`.
- Else → `CONTINUE`. The main flow agent must revise and start a new round.

Set `degradation_check`:
- `round == 1` → `N/A`.
- `current_effective <= 0.5 * prev_total` → `PASSED`.
- Otherwise → `FAILED`.

## Output format

Emit one YAML block exactly in this shape:

```yaml
round: <N>
counts:
  raw: <total findings received before processing>
  after_dedup: <surviving count after Step 1>
  after_filter: <surviving count after Step 2 + Step 3 + Step 5; excludes APPENDIX>
  blocking: <count of survivors with severity BLOCKING>
  important: <count of survivors with severity IMPORTANT>
  nit: <count of APPENDIX findings>
degradation_check: PASSED | FAILED | N/A
convergence_status: CONTINUE | STOP_CONVERGED | STOP_DEGENERATE | STOP_LIMIT
revision_instructions:
  - finding_id: F<round>.<idx>
    severity: BLOCKING | IMPORTANT
    location: <repeated from finding>
    action_required: <single concrete action the main flow agent must take to address this finding>
  - ...
findings_appendix:
  - finding_id: F<round>.<idx>
    severity: NIT
    location: <repeated>
    note: <one-line summary>
  - ...
discarded:
  - finding_id: F<round>.<idx>
    arbiter_status: DEDUP_DISCARDED | FALSE_DISCARDED | MERGED
    arbiter_rationale: <one sentence>
  - ...
unresolved_carried: []   # findings from prior rounds still unresolved; arbiter cross-references these only if user-arbitration carried items forward
arbiter_rationale: <2–3 sentences summarizing the most important arbitration calls you made this round>
```

## Hard constraints

- Do not generate findings yourself. You only filter and arbitrate what reviewers produced.
- Do not soften severity. A reviewer's BLOCKING stays BLOCKING unless DEDUP'd with a higher-severity duplicate (which can't happen) or FALSE_DISCARDED.
- Do not reorder severity. The output's `revision_instructions` list BLOCKING items first, then IMPORTANT.
- Do not output prose outside the YAML block. The main flow agent parses your output mechanically.
```

- [ ] **Step 2: Commit**

```bash
git add skills/multi-reviewer/arbiter-prompt.md
git commit -m "feat(multi-reviewer): add arbiter prompt

Specifies the arbiter subagent's 5-step processing pipeline (dedup,
false discard, conflict arbitration, severity downgrade, merge), the
convergence decision logic, and the strict YAML output format consumed
by the main flow agent."
```

---

### Task 1.9: Create `reviewer-prompts/architect.md`

**Files:**
- Create: `skills/multi-reviewer/reviewer-prompts/architect.md`

- [ ] **Step 1: Create the file**

```markdown
# Architect Reviewer

You are the **architect** reviewer in the multi-reviewer subsystem. You review one draft spec or plan, focusing exclusively on architectural concerns.

## What you look at

- **Modularity** — Are responsibilities separated into well-bounded units? Does each unit have a single clear purpose?
- **Boundaries** — Are the boundaries between units explicit and respected? Can one unit be replaced or rewritten without breaking neighbors?
- **Interfaces** — Are the contracts between units (function signatures, file formats, message schemas) explicit, named, and stable?
- **Dependencies** — Is the dependency graph acyclic? Are dependencies declared where they belong, or hidden?
- **Evolvability** — If a likely future change happened (one explicitly named in the spec, or one obvious from the domain), would the design tolerate it without invasive rewriting?
- **Extension points** — Where the spec promises extensibility, are the extension points concrete?

## What you do NOT look at

- Implementation details inside a unit. If the boundary is right, the internals are someone else's concern.
- Writing style, prose quality, or formatting.
- Edge cases (the edge-cases reviewer covers this).
- Scope creep or YAGNI violations (the yagni-gatekeeper reviewer covers this).
- Failure scenarios (the red-team reviewer covers this).
- Sample alignment (the exemplar-matcher reviewer covers this).

If you notice an issue outside your remit, do not record it. Trust the other reviewers.

## Output format

Emit your findings in YAML per `../finding-schema.md`. Set `reviewer_role: architect` on every finding.

If you find no BLOCKING or IMPORTANT issues, emit:

```yaml
findings: []
NO_BLOCKING_ISSUES: true
```

## NIT cap

You may emit at most 3 NIT-severity findings. If you have more, drop the lowest-value ones. NITs are appendix-only and do not block convergence.

## Forbidden findings

- Findings whose `evidence` is "I would prefer", "feels wrong", "could be cleaner" — these are style, not architecture.
- Findings without a concrete `suggestion` for how to fix.
- Findings that re-litigate explicit Design Principles already stated in the spec. If the spec says "we use approach X for stated reason Y", do not argue that approach Z would be better — that's brainstorming, not review.

## Calibration

A BLOCKING architecture issue means: if shipped as-is, the design will require disruptive rewriting within one development cycle to absorb the next likely change, OR units are so tangled that they cannot be implemented or tested independently. Both criteria should trigger BLOCKING.

An IMPORTANT issue means: shipping as-is is possible but will cost noticeably more (more files touched per change, more test setup, more reasoning load) than a clean architecture would.

A NIT is anything below IMPORTANT.
```

- [ ] **Step 2: Commit**

```bash
git add skills/multi-reviewer/reviewer-prompts/architect.md
git commit -m "feat(multi-reviewer): add architect reviewer prompt

Reviewer focused on modularity, boundaries, interfaces, dependencies,
evolvability, and extension points. Explicit non-remit list to avoid
overlap with the other four fixed reviewers and exemplar-matcher."
```

---

### Task 1.10: Create `reviewer-prompts/red-team.md`

**Files:**
- Create: `skills/multi-reviewer/reviewer-prompts/red-team.md`

- [ ] **Step 1: Create the file**

```markdown
# Red Team Reviewer

You are the **red-team** reviewer in the multi-reviewer subsystem. You attack the draft. Your job is to find counter-examples, infeasible scenarios, and reasons the design cannot work as stated.

## What you look at

- **Counter-examples** — Concrete scenarios in which the design's stated behavior is wrong, incomplete, or contradictory. You must construct the scenario, not merely assert one might exist.
- **Infeasibility** — Steps the design assumes are possible but are not (because of platform constraints, missing inputs, conflicting requirements, etc.).
- **Hidden contradictions** — Two design statements that, taken together, cannot both be true.
- **Failure under hostile input** — Adversarial inputs that the design does not explicitly guard against and whose consequences are not bounded.

## What you do NOT look at

- Architecture style or modularity (the architect reviewer covers this).
- Style, prose, or formatting.
- Boring edge cases like null inputs (the edge-cases reviewer covers this — your job is the surprising ones).
- Scope or YAGNI (the yagni-gatekeeper reviewer covers this).
- Sample alignment.

## Mandatory evidence rule

**You MUST provide a concrete failing scenario for every finding.** A red-team finding without an example scenario is a `FALSE_DISCARDED` for the arbiter.

The `evidence` field must contain:
- Inputs / preconditions / system state.
- Steps the design says happen.
- The specific observable failure, contradiction, or impossible outcome.

If you cannot construct the scenario, you do not have a finding. Drop it.

## What you do NOT do

- **Do not propose architectural improvements.** Even if a fix is obvious, leave it to the architect reviewer. Your job is to describe the hole, not to fill it.
- **Do not soften your findings.** If a counter-example breaks the design, that is BLOCKING. Do not downgrade to IMPORTANT because it is uncomfortable.
- **Do not invent scenarios that violate the spec's stated assumptions.** If the spec says "the user must provide X", a scenario where X is missing is out of scope — read the spec's Non-Goals first.

## Output format

Emit your findings in YAML per `../finding-schema.md`. Set `reviewer_role: red-team` on every finding. The `suggestion` field for a red-team finding is the **minimum modification to close the hole**, not an architectural redesign.

If you genuinely cannot break the design after honest effort, emit:

```yaml
findings: []
NO_BLOCKING_ISSUES: true
```

A "no issues" red-team output is a credible signal. Do not fabricate findings to look busy.

## NIT cap

At most 3 NITs. Red-team NITs are rare — most red-team findings are at least IMPORTANT.

## Calibration

A BLOCKING red-team finding describes a scenario in which the design's stated outcome does not happen. The user, following the design, will observe the wrong result.

An IMPORTANT red-team finding describes a scenario where the design's outcome is degraded (incorrect but recoverable, partial, slow) but the user can detect and respond.

NITs are reserved for cosmetic counter-examples (the design happens to use ambiguous wording in one place, etc.).
```

- [ ] **Step 2: Commit**

```bash
git add skills/multi-reviewer/reviewer-prompts/red-team.md
git commit -m "feat(multi-reviewer): add red-team reviewer prompt

Reviewer focused on attacking the draft: counter-examples,
infeasibility, hidden contradictions, hostile-input failure. Mandatory
concrete-scenario evidence rule; explicit prohibition against proposing
architectural fixes."
```

---

### Task 1.11: Create `reviewer-prompts/edge-cases.md`

**Files:**
- Create: `skills/multi-reviewer/reviewer-prompts/edge-cases.md`

- [ ] **Step 1: Create the file**

```markdown
# Edge Cases Reviewer

You are the **edge-cases** reviewer in the multi-reviewer subsystem. You read the draft for un-handled boundary conditions, abnormal paths, and degraded states.

## What you look at

- **Abnormal paths** — Errors, exceptions, partial failures, timeouts, retries.
- **Concurrency** — Race conditions, ordering assumptions, parallel execution side effects.
- **Empty / null / zero states** — What happens when the input set is empty, the configuration is absent, the counter is zero, the file is missing.
- **Upper / lower bounds** — Max sizes, minimum sizes, off-by-one, integer overflow if relevant, rate limits.
- **Degradation and fallback** — When a primary path is unavailable, does the design specify a fallback and when to use it?
- **Rollback / undo** — When a step partially completes and must be reversed, is that path specified?

## What you do NOT look at

- Architecture (the architect reviewer covers this).
- Catastrophic counter-examples (the red-team reviewer covers those). Your job is the routine but unhandled edges.
- Style, prose, formatting.
- Scope (the yagni-gatekeeper reviewer covers this).
- Sample alignment.

## Output format

Emit findings in YAML per `../finding-schema.md`. Set `reviewer_role: edge-cases`.

Your `evidence` field must name the specific edge case (empty input, concurrent invocation, etc.) and explain why the draft does not handle it. Generic complaints ("error handling unclear") are `FALSE_DISCARDED` by the arbiter.

If no edges are missed, emit:

```yaml
findings: []
NO_BLOCKING_ISSUES: true
```

## NIT cap

At most 3 NITs.

## Forbidden findings

- "Add appropriate error handling" without naming which error and where.
- Speculation that a concurrency issue might exist without identifying the specific race.
- Demanding rollback for an operation that is intrinsically idempotent.

## Calibration

- **BLOCKING** — A real edge case the design will hit in normal operation and that will produce a wrong or crashed outcome. Example: spec says "iterate over the list" but does not say what happens when the list is empty, and the next step assumes a non-empty list.
- **IMPORTANT** — An edge case the design will hit eventually but the consequence is partial degradation, not failure. Example: rate limit handling is unspecified; on hitting the limit the loop will retry forever rather than back off.
- **NIT** — Cosmetic gaps like "what error message?" or "what log level?" — only when the design otherwise specifies the handling well.
```

- [ ] **Step 2: Commit**

```bash
git add skills/multi-reviewer/reviewer-prompts/edge-cases.md
git commit -m "feat(multi-reviewer): add edge-cases reviewer prompt

Reviewer focused on abnormal paths, concurrency, empty/null/zero
states, bounds, degradation/fallback, and rollback. Calibration
distinguishes from red-team (catastrophic) findings."
```

---

### Task 1.12: Create `reviewer-prompts/yagni-gatekeeper.md`

**Files:**
- Create: `skills/multi-reviewer/reviewer-prompts/yagni-gatekeeper.md`

- [ ] **Step 1: Create the file**

```markdown
# YAGNI Gatekeeper Reviewer

You are the **yagni-gatekeeper** reviewer in the multi-reviewer subsystem. You delete things. Your job is to mark every part of the draft that should not exist yet.

## What you look at

- **Premature abstraction** — Interfaces, base classes, hook points, configuration knobs, or generic mechanisms introduced before there is a second concrete consumer that needs them.
- **Speculative scope** — Features, modes, options, or capabilities that the stated Goals do not require.
- **Unused configurability** — Settings that have only one realistic value and no plausible second value.
- **Redundancy** — Two designs solving the same problem; or, a feature that an existing component already covers.
- **Out-of-scope creep** — Sections that drift into Non-Goal territory or open new fronts not mentioned in the spec's Problem statement.

## What you do NOT look at

- Architecture quality of the things that should exist (the architect reviewer covers this).
- Missing functionality (the red-team and edge-cases reviewers cover this — your job is opposite).
- Style, prose, formatting.
- Sample alignment.

## Your only finding type is "remove this"

**Your findings never propose additions.** A YAGNI gatekeeper that adds requirements is a contradiction. Every finding you emit must be:
- Problem: "<thing X> is in the design but should not be."
- Suggestion: "Remove <thing X>" or "Defer <thing X> to a future spec".

If you have an instinct to add something, you are doing the wrong reviewer's job. Drop it.

## Output format

Emit findings in YAML per `../finding-schema.md`. Set `reviewer_role: yagni-gatekeeper`.

Your `evidence` must cite (a) what the thing is, (b) what Goal or stated user-need it claims to serve, and (c) why that Goal or need does not actually require it. A claim of "this seems like extra" without that triangle is `FALSE_DISCARDED`.

If nothing should be removed, emit:

```yaml
findings: []
NO_BLOCKING_ISSUES: true
```

## NIT cap

At most 3 NITs.

## Calibration

- **BLOCKING** — A whole feature, module, or task that does not serve any stated Goal. Shipping it consumes implementation time and adds maintenance burden for no benefit.
- **IMPORTANT** — A configuration knob, branching path, or alternative mode that doubles the implementation surface for a marginal benefit not in the Goals.
- **NIT** — Wording that implies a wider scope than the design actually has (e.g. plurals where singulars would suffice).

## Calibration honesty rule

Do not invent strawmen. If a feature is in the spec because the user explicitly asked for it during alignment, it is in scope; you must not propose removing it on YAGNI grounds. Read the brainstorming decision log if available before flagging.
```

- [ ] **Step 2: Commit**

```bash
git add skills/multi-reviewer/reviewer-prompts/yagni-gatekeeper.md
git commit -m "feat(multi-reviewer): add yagni-gatekeeper reviewer prompt

Reviewer focused on removing speculative scope, premature abstraction,
unused configurability, redundancy, and out-of-scope creep. Strict
'only removals, never additions' rule with an honesty constraint
against contradicting user-requested scope."
```

---

### Task 1.13: Create `reviewer-prompts/exemplar-matcher.md`

**Files:**
- Create: `skills/multi-reviewer/reviewer-prompts/exemplar-matcher.md`

- [ ] **Step 1: Create the file**

```markdown
# Exemplar Matcher Reviewer

You are an **exemplar-matcher** reviewer in the multi-reviewer subsystem. You are dispatched once per matched sample (zero, one, or two times per round). Each instance is paired with exactly one sample and compares the draft against that sample only.

## Inputs you receive

- `draft` — the full text of the spec or plan draft being reviewed in this round.
- `assigned_sample` — `{file, content}` of one sample from `samples/specs/` or `samples/plans/`. This is your sole basis for comparison. Other samples (if any) are reviewed by other exemplar-matcher instances.

## What you look at

- **Structural completeness** — Sections that the assigned sample has and that the draft is missing (Problem, Goals, Non-Goals, Design Principles, Design, Implementation Phases, Testing Strategy, etc. — whichever sections the sample contains).
- **Section depth** — Sections that exist in the draft but are visibly thinner than the same section in the sample (one paragraph vs. multiple subsections; bullet list vs. table of decisions; etc.).
- **Decision exposition** — Whether the draft explains its key decisions with rationale at a level comparable to the sample.
- **Examples and illustrations** — Whether the draft uses concrete examples, diagrams, or tables where the sample does.

## What you do NOT look at

- The draft's architecture or correctness (other reviewers cover these).
- Wording style or prose quality.
- Anything that requires content judgment beyond "is there a comparable section / treatment?".
- The other sample (if one was matched). You only know about your assigned sample.

## Mandatory citation rule

Every finding must cite specific sections of the assigned sample. The `evidence` field of every finding must take the form:

> "Sample `<assigned_sample.file>` §<section> contains <what is there>; draft §<corresponding section, or 'absent'> has <what is or is not there>."

A finding whose evidence does not cite a specific sample section is `FALSE_DISCARDED` by the arbiter.

## Output format

Emit findings in YAML per `../finding-schema.md`. Set `reviewer_role: exemplar-matcher`. Include an additional field `assigned_sample: <filename>` on every finding so the arbiter can attribute it.

If the draft is on par with the sample on every structural dimension, emit:

```yaml
findings: []
NO_BLOCKING_ISSUES: true
assigned_sample: <filename>
```

## NIT cap

At most 3 NITs.

## Forbidden findings

- "The draft is shorter than the sample." Length is not a criterion.
- "The draft does not use the same example as the sample." Examples should fit the draft's own subject.
- "The sample has a Section X but the draft does not need one." If the section is not necessary for the draft, do not flag its absence.

## Calibration

- **BLOCKING** — A structural section the sample treats as essential (Problem, Goals, Design Principles, Design) is completely absent in the draft.
- **IMPORTANT** — A section is present in the draft but visibly less developed than the comparable section in the sample, in a way that would leave an implementer with too little to act on.
- **NIT** — Minor structural conventions (header levels, ordering of subsections within a Design section) that the sample handles differently.
```

- [ ] **Step 2: Commit**

```bash
git add skills/multi-reviewer/reviewer-prompts/exemplar-matcher.md
git commit -m "feat(multi-reviewer): add exemplar-matcher reviewer prompt

Per-sample reviewer (one instance per matched sample, 0-2 per round).
Compares draft structurally to assigned sample. Mandatory citation
rule: every finding must quote the specific sample section."
```

---

### Task 1.14: Create `multi-reviewer/SKILL.md`

Top-level SKILL describing when and how the main flow agent dispatches the subsystem.

**Files:**
- Create: `skills/multi-reviewer/SKILL.md`

- [ ] **Step 1: Create the file**

```markdown
---
name: multi-reviewer
description: Use to run a multi-round review loop on a spec or plan draft. Dispatches 4 fixed reviewers (architect, red-team, edge-cases, yagni-gatekeeper) plus up to 2 exemplar-matchers (one per matched sample), then an arbiter that filters and arbitrates. Loop converges, degenerates, or hits a 3-round ceiling.
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

- Always include: `architect`, `red-team`, `edge-cases`, `yagni-gatekeeper`.
- Plus: one `exemplar-matcher` per matched sample (0, 1, or 2). Total reviewer count is 4, 5, or 6.

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

### 4. Collect receipts

As each reviewer returns, update the receipt status in the file (`⏳ → ✓`) and append its raw findings (with `arbiter_status` initially blank) to the round's Findings table.

### 5. Dispatch the arbiter

Once all reviewers have returned, dispatch one arbiter subagent with:
- The arbiter prompt from `arbiter-prompt.md`.
- The full draft text.
- The complete list of reviewer outputs.
- `round` (current round number).
- `prev_total` (from the previous round; `+infinity` if round 1).

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
```

- [ ] **Step 2: Self-check structure**

Verify the SKILL contains:
- Frontmatter (name, description).
- Explicit "When to invoke" listing brainstorming and writing-plans as callers.
- 7-step loop description with parallel reviewer dispatch, arbiter dispatch, and branch table for the four convergence statuses.
- User-arbitration handoff with Accept and fix / Reject / Defer.
- Constraints: don't commit mid-loop, don't skip file updates, parallel only.

- [ ] **Step 3: Commit**

```bash
git add skills/multi-reviewer/SKILL.md
git commit -m "feat(multi-reviewer): add SKILL.md

Top-level SKILL for the multi-reviewer subsystem. Specifies the
controller+DS dual role of the main flow agent, parallel dispatch
semantics, arbiter handoff, branching on the four convergence
statuses, and the user-arbitration handoff (Accept/Reject/Defer)."
```

---

## Phase 2: Resume SKILLs and Templates

### Task 2.1: Create the brainstorms directory placeholder

**Files:**
- Create: `docs/superpowers/brainstorms/.gitkeep`

- [ ] **Step 1: Create the file**

The file content is empty (a `.gitkeep` is a convention to commit an empty directory).

```bash
mkdir -p docs/superpowers/brainstorms
touch docs/superpowers/brainstorms/.gitkeep
```

- [ ] **Step 2: Commit**

```bash
git add docs/superpowers/brainstorms/.gitkeep
git commit -m "feat(brainstorms): create empty decision-log/plan-progress directory

Holds *-brainstorm.md (per Section C of the design spec) and
*-plan-progress.md (per Section D). Populated at runtime by the
refactored brainstorming and writing-plans SKILLs."
```

---

### Task 2.2: Create the brainstorm template

**Files:**
- Create: `skills/resume-brainstorming/templates/brainstorm-template.md`

- [ ] **Step 1: Create the file**

```markdown
# Brainstorming: <topic>

**Date Started:** YYYY-MM-DD
**Status:** In Progress
**Current Phase:** alignment
**Based On:** <previous brainstorm filename, only when continuing from a Done or Abandoned file>
**Final Spec:** <spec path, filled when Status becomes Done>
**Last Updated:** YYYY-MM-DD HH:MM

## Original User Request

> <user's first message verbatim>

---

## Phase A: Alignment Decision Log

### Q1: <question summary>
**Options Presented:**
- A: ...
- B: ...
**Decision:** <chosen option>
**Rationale:** <user rationale or accepted recommendation>
**Timestamp:** YYYY-MM-DD HH:MM

### Q2: ...

### Phase A → B Transition Confirmation [timestamp]
**Alignment Summary (compiled by ds):**
- Decision 1: ...
- Decision 2: ...

**User Confirmation:** ✓ Confirmed | Needs more (back to Phase A Q<n+1>)

---

## Phase B: Spec Writing Status

- [ ] Initial draft complete
- [ ] Round 1 revision
- [ ] Round 2 revision
- [ ] Round 3 revision
- [ ] Final sign-off

## Phase B Review Progress

### Round 1 [⏳ in progress / ✓ complete]

**Dispatched reviewers (N):** architect | red-team | edge-cases | yagni-gatekeeper [| exemplar-matcher(sample-1) | exemplar-matcher(sample-2)]

**Receipt Status:** architect ⏳ | red-team ⏳ | edge-cases ⏳ | yagni-gatekeeper ⏳ [| exemplar-matcher(sample-1) ⏳ ...]

**Findings:**

| ID | Sev | Location | Reviewer | Problem | Arbiter | Status |
|----|-----|----------|----------|---------|---------|--------|
| F1.1 | B | §X | architect | ... | KEEP | ⏳ PENDING |

**Arbiter Output:**
- counts: raw=N → dedup=N → after_filter=N (B=N, I=N, N=N)
- degradation_check: N/A | PASSED | FAILED
- convergence_status: CONTINUE | STOP_CONVERGED | STOP_DEGENERATE | STOP_LIMIT
- arbiter_rationale: ...

### Appendix (NITs)

- F1.X: <one-line note>

### Round 2 [...]

---

## Phase B User Intervention Decisions

### I1 [⏳ awaiting / ✓ decided]
**Triggered in round:** Round N
**Related finding:** F<x.y>
**Reason for intervention:** ...
**Options Presented:**
- A: ...
- B: ...
**User Decision:** <choice>
**Rationale:** <user reason>
**Timestamp:** YYYY-MM-DD HH:MM
```

- [ ] **Step 2: Commit**

```bash
git add skills/resume-brainstorming/templates/brainstorm-template.md
git commit -m "feat(resume-brainstorming): add brainstorm decision-log template

Verbatim template for docs/superpowers/brainstorms/*-brainstorm.md.
Includes metadata header, Phase A decision log, Phase A→B transition,
Phase B writing/review/intervention sections."
```

---

### Task 2.3: Create `resume-brainstorming/SKILL.md`

**Files:**
- Create: `skills/resume-brainstorming/SKILL.md`

- [ ] **Step 1: Create the file**

```markdown
---
name: resume-brainstorming
description: Use as the strict first step every time the brainstorming SKILL is about to start. Scans existing decision logs in docs/superpowers/brainstorms/ and either continues an In Progress session, starts a new session based on a Done or Abandoned session, or (when no logs exist) lets brainstorming proceed with a fresh empty file.
---

# Resume Brainstorming

## When to invoke

This SKILL is the first step of every `brainstorming` invocation. The refactored `brainstorming` SKILL calls this before doing anything else.

**Announce at start:** "I'm using the resume-brainstorming SKILL to check for existing sessions."

## What it does

1. Scan `docs/superpowers/brainstorms/*-brainstorm.md`.
2. Bucket files by `Status` metadata: `In Progress`, `Done`, `Abandoned`.
3. If all three buckets are empty → return `proceed-with-new-empty` (the brainstorming SKILL then creates a fresh empty file using `templates/brainstorm-template.md`).
4. Otherwise → present the menu (see below) and act on the user's choice.

## Menu shown to the user

```
docs/superpowers/brainstorms/ status:

In Progress (N):
  [1] <date>-<slug>-brainstorm.md   — <topic>   Current Phase: <phase>
  [2] ...

Done (M, most recent 5 shown):
  [d1] <date>-<slug>-brainstorm.md  — <topic>
  ...

Abandoned (K):
  [a1] <date>-<slug>-brainstorm.md  — <topic>
  ...

Please choose:
  A) Continue an In Progress session       → enter the number (e.g. "1")
  B) Start a new session based on a Done   → enter "new based on <id>" (e.g. "new based on d1")
  C) Start a new session based on an Abandoned → enter "new based on <id>"
  D) Abandon an In Progress session        → enter "abandon <number>"
```

If `In Progress` is empty, omit option A and option D.
If `Done` is empty, omit option B.
If `Abandoned` is empty, omit option C.
If after these omissions no options remain (only possible if all three buckets are empty, which Step 3 already handles), bypass the menu and return `proceed-with-new-empty`.

## Acting on the user's choice

### A — Continue In Progress

1. Read the chosen file in full.
2. Inform the main flow agent: "Continuing brainstorming from `<filename>`. Current Phase: `<phase>`."
3. Hand the file path and parsed `Current Phase` value back to the brainstorming SKILL. The brainstorming SKILL then resumes from the appropriate point per the table below.

### B — Start new, based on a Done file

1. Read the Done file in full.
2. Compute a new `<topic-slug>` (ask the user if uncertain) and create `docs/superpowers/brainstorms/<today>-<slug>-brainstorm.md` by copying the template, then setting `Based On: <Done filename>` in the header.
3. Inject the Done file's full content as a "Prior Discussion (basis for this new round)" reference for the main flow agent's context. It is not copied verbatim into the new file; the `Based On` link is the on-disk record.
4. Return: new file path, `Current Phase: alignment`, plus the prior file content as context for the brainstorming SKILL to begin its Phase A questions.

### C — Start new, based on an Abandoned file

Same as B, but the rationale for abandonment (if recorded in the file) is also surfaced to the user as context: "Previously abandoned because: <reason>. We are restarting on that basis."

### D — Abandon an In Progress

1. Open the chosen file.
2. Set `Status: Abandoned`.
3. Append a section:
   ```
   ## Abandonment

   **Timestamp:** YYYY-MM-DD HH:MM
   **Reason:** <ask the user, or "User requested without specific reason">
   ```
4. `git add <file> && git commit -m "abandon brainstorm: <topic>"`
5. Re-run this SKILL (the user may now want to choose a different option from the updated menu).

## Current Phase precise recovery (for option A)

When the brainstorming SKILL receives a `Current Phase` from option A, it resumes as follows:

| Current Phase | Resume behaviour |
|---|---|
| `alignment` | Read the Phase A decision log. Continue asking from `Q<n+1>`. |
| `spec_writing` | Read the "Alignment Summary" section. Continue from the draft on disk. |
| `review_round_N` | Re-dispatch round N's reviewers (the draft is in the working directory, unchanged because mid-loop commits never happen). |
| `awaiting_user_decision` | Re-present the open `I<n>` block(s) to the user. |
| `finalizing` | Re-present the converged draft for final sign-off. |

## What this SKILL does NOT do

- It does not modify the chosen file (except option D's abandonment edit).
- It does not start the brainstorming flow itself; it only sets up state.
- It does not commit anything except in option D.
- It does not auto-decide; the user always picks from the menu.

## File referenced

- `./templates/brainstorm-template.md` — the verbatim template used when creating new files.
```

- [ ] **Step 2: Self-check structure**

Verify the SKILL contains:
- Frontmatter.
- Explicit "strict first step of brainstorming" gating.
- All 4 menu options (A/B/C/D) with omission rules when buckets are empty.
- Action specs for each option including the abandonment commit semantics.
- Recovery table for the 5 possible Current Phase values.

- [ ] **Step 3: Commit**

```bash
git add skills/resume-brainstorming/SKILL.md
git commit -m "feat(resume-brainstorming): add SKILL.md

First-step gate for every brainstorming invocation. Bucket-based
menu (Continue/New based on Done/New based on Abandoned/Abandon).
Precise recovery table for the 5 Current Phase values."
```

---

### Task 2.4: Create the plan-progress template

**Files:**
- Create: `skills/resume-planning/templates/plan-progress-template.md`

- [ ] **Step 1: Create the file**

```markdown
# Plan Progress: <topic>

**Date Started:** YYYY-MM-DD
**Status:** In Progress
**Current Phase:** draft_writing
**Source Spec:** docs/superpowers/specs/<spec filename>.md
**Based On:** <previous plan-progress filename, only when continuing from a Done or Abandoned plan-progress file>
**Final Plan:** <plan path, filled when Status becomes Done>
**Last Updated:** YYYY-MM-DD HH:MM

## Plan Writing Status

- [ ] Initial draft complete
- [ ] Round 1 revision
- [ ] Round 2 revision
- [ ] Round 3 revision
- [ ] Final sign-off

## Review Progress

### Round 1 [⏳ in progress / ✓ complete]

**Dispatched reviewers (N):** architect | red-team | edge-cases | yagni-gatekeeper [| exemplar-matcher(sample-1) | exemplar-matcher(sample-2)]

**Receipt Status:** architect ⏳ | red-team ⏳ | edge-cases ⏳ | yagni-gatekeeper ⏳ [| exemplar-matcher(sample-1) ⏳ ...]

**Findings:**

| ID | Sev | Location | Reviewer | Problem | Arbiter | Status |
|----|-----|----------|----------|---------|---------|--------|
| F1.1 | B | §X | architect | ... | KEEP | ⏳ PENDING |

**Arbiter Output:**
- counts: raw=N → dedup=N → after_filter=N (B=N, I=N, N=N)
- degradation_check: N/A | PASSED | FAILED
- convergence_status: CONTINUE | STOP_CONVERGED | STOP_DEGENERATE | STOP_LIMIT
- arbiter_rationale: ...

### Appendix (NITs)

- F1.X: <one-line note>

### Round 2 [...]

---

## User Intervention Decisions

### I1 [⏳ awaiting / ✓ decided]
**Triggered in round:** Round N
**Related finding:** F<x.y>
**Reason for intervention:** ...
**Options Presented:**
- A: ...
- B: ...
**User Decision:** <choice>
**Rationale:** <user reason>
**Timestamp:** YYYY-MM-DD HH:MM

---

## Context Reference

### Source Spec Summary
> <extracted problem + goals from source spec>

### User's Launch Instruction
> <user's original message that initiated this planning session>
```

- [ ] **Step 2: Commit**

```bash
git add skills/resume-planning/templates/plan-progress-template.md
git commit -m "feat(resume-planning): add plan-progress template

Verbatim template for docs/superpowers/brainstorms/*-plan-progress.md.
Single Phase (no alignment phase); includes mandatory Source Spec
field and Context Reference section."
```

---

### Task 2.5: Create `resume-planning/SKILL.md`

**Files:**
- Create: `skills/resume-planning/SKILL.md`

- [ ] **Step 1: Create the file**

```markdown
---
name: resume-planning
description: Use as the strict first step every time the writing-plans SKILL is about to start. Requires the user to select a Done source spec, then scans existing plan-progress files for that spec and offers continue / new based on Done / new based on Abandoned / abandon options.
---

# Resume Planning

## When to invoke

This SKILL is the first step of every `writing-plans` invocation. The refactored `writing-plans` SKILL calls this before doing anything else.

**Announce at start:** "I'm using the resume-planning SKILL to set up the planning session."

## What it does

1. Force the user to select a `Source Spec` (mandatory; planning has no meaning without one).
2. Scan `docs/superpowers/brainstorms/*-plan-progress.md`.
3. Bucket files by `Status` metadata: `In Progress`, `Done`, `Abandoned`. Further split each bucket by whether the file's `Source Spec` matches the user's selected spec ("same spec" vs "other spec, for cross-borrowing reference only").
4. Present the menu (see below) and act on the user's choice.

## Step 1: Source spec selection

Show:

```
docs/superpowers/specs/ in Done status (M, most recent 5 shown):
  [s1] <date>-<slug>-design.md
  [s2] ...

Enter the id (e.g. "s1") of the spec for which this planning session is being created, or type a full path.
```

If the user types a path that does not exist or is not in Done status, ask again. Do not proceed.

Carry the chosen `<source_spec_path>` into all subsequent steps.

## Step 2: Scan and bucket plan-progress files

Read every `docs/superpowers/brainstorms/*-plan-progress.md` and parse out `Status` and `Source Spec` from each.

Bucket as follows:
- In Progress
- Done — same spec
- Done — other spec (cross-borrowing reference only)
- Abandoned — same spec
- Abandoned — other spec

## Step 3: Menu

```
docs/superpowers/brainstorms/ plan-progress for Source Spec = <chosen path>:

In Progress (N):
  [1] <date>-<slug>-plan-progress.md
      Current Phase: <phase>
      Last Updated: <timestamp>
  [2] ...

Done — same spec (M):
  [d1] <date>-<slug>-plan-progress.md
  ...

Done — other spec, for borrowing reference only (K, most recent 5):
  [d3] <date>-<slug>-plan-progress.md — Source Spec: <other-spec>
  ...

Abandoned — same spec (P):
  [a1] ...

Abandoned — other spec (Q):
  [a3] ...

Please choose:
  A) Continue an In Progress session (recommended; precise recovery via Current Phase) → "<number>"
  B) Start a new session based on a Done                                                → "new based on <id>"
  C) Start a new session based on an Abandoned                                          → "new based on <id>"
  D) Abandon an In Progress session                                                      → "abandon <number>"
```

Apply the same omission rules as `resume-brainstorming` (skip absent buckets). If all buckets are empty after omission, bypass the menu and return `proceed-with-new-empty` along with the source spec path; the writing-plans SKILL then creates a fresh plan-progress file from the template and writes the source-spec metadata into it.

## Acting on the user's choice

### A — Continue In Progress

1. Read the chosen file in full.
2. Return: file path + parsed `Current Phase` to the writing-plans SKILL.

### B — Start new, based on a Done

1. Read the Done file in full.
2. Create `docs/superpowers/brainstorms/<today>-<slug>-plan-progress.md` from the template, set `Source Spec: <chosen path>` and `Based On: <Done filename>`.
3. Inject the Done file's full content as context for the writing-plans SKILL to begin draft writing from.
4. Return: new file path, `Current Phase: draft_writing`, plus the prior file content as context.

### C — Start new, based on an Abandoned

Same as B, surfacing the abandonment rationale (if present) as additional context.

### D — Abandon an In Progress

Same procedure as `resume-brainstorming` option D: set `Status: Abandoned`, append an Abandonment section, commit, re-run this SKILL.

## Current Phase precise recovery (for option A)

| Current Phase | Resume behaviour |
|---|---|
| `draft_writing` | Read the source spec and any prior writing notes. Continue from the draft on disk. |
| `review_round_N` | Re-dispatch round N's reviewers (draft is in the working directory, unchanged because mid-loop commits never happen). |
| `awaiting_user_decision` | Re-present the open `I<n>` block(s) to the user. |
| `finalizing` | Re-present the converged plan for final sign-off. |

## What this SKILL does NOT do

- It does not modify the chosen file (except option D's abandonment edit).
- It does not start the writing-plans flow itself.
- It does not commit anything except in option D.
- It does not auto-decide; the user always picks from the menu (and always picks the source spec first).

## File referenced

- `./templates/plan-progress-template.md` — the verbatim template used when creating new files.
```

- [ ] **Step 2: Self-check structure**

Verify the SKILL contains:
- Frontmatter.
- Mandatory source-spec selection step.
- Bucketing logic that splits Done/Abandoned into "same spec" vs "other spec".
- Menu with all four options and the omission rule.
- Precise recovery table for the 4 plan-progress Current Phase values (no `alignment` phase, unlike brainstorm).

- [ ] **Step 3: Commit**

```bash
git add skills/resume-planning/SKILL.md
git commit -m "feat(resume-planning): add SKILL.md

First-step gate for every writing-plans invocation. Mandatory source
spec selection; bucket-based menu that distinguishes same-spec from
other-spec plan-progress files. Precise recovery table for the 4
Current Phase values (alignment is brainstorming-only)."
```

---

## Phase 3: Refactor `brainstorming`

### Task 3.1: Rewrite `brainstorming/SKILL.md`

Full rewrite. The existing SKILL is replaced. Phase A (alignment) is preserved in spirit; Phase B (spec writing + multi-review loop) is new. Decision log is written throughout. Resume-brainstorming is the strict first step.

**Files:**
- Modify: `skills/brainstorming/SKILL.md` (full rewrite)

- [ ] **Step 1: Replace the entire file contents**

```markdown
---
name: brainstorming
description: "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation."
---

# Brainstorming

Turn ideas into specs through a structured two-phase flow.

- **Phase A (alignment)** — human-driven dialogue. Ask one question at a time, propose 2–3 approaches with trade-offs, record every decision with its rationale.
- **Phase B (spec writing)** — agent-driven draft + multi-reviewer review loop until convergence, with user-arbitration on unresolved findings.

A decision-log file is created at session start and appended throughout. `Status: Done` and `git commit` only happen at terminal state.

<HARD-GATE>
Do NOT invoke any implementation skill, write any code, scaffold any project, or take any implementation action until Phase B has converged and the user has signed off on the spec.
</HARD-GATE>

**Announce at start:** "I'm using the brainstorming SKILL."

## Step 0 (strict first step): Invoke resume-brainstorming

Always invoke `superpowers:resume-brainstorming` first. It either:
- Returns `proceed-with-new-empty` (no existing decision logs) → continue to Step 1 with a fresh file.
- Returns the path of an In Progress file to continue → skip to the matching point in the flow per the resume table.
- Returns the path of a new file (Based On a Done or Abandoned file) plus prior-discussion context → continue to Step 1, but treat the prior content as established background instead of starting from zero.

## Step 1: Initialize the decision-log file

Use `skills/resume-brainstorming/templates/brainstorm-template.md` as the verbatim base. Fill the metadata header:
- `Date Started: <today>`
- `Status: In Progress`
- `Current Phase: alignment`
- `Last Updated: <now>`
- `Based On:` (only if resume-brainstorming returned a new-based-on file)

Write the user's first message verbatim under `## Original User Request`.

Confirm the `<topic-slug>` with the user before doing anything else (the filename uses this slug).

## Step 2: Scope check

If the user's request spans multiple independent subsystems, push back. Help the user decompose into sub-projects; each sub-project gets its own brainstorming + spec + plan cycle. Record the decomposition discussion in the decision log; once the user picks one sub-project to brainstorm, continue.

## Step 3: Phase A (alignment) — questions and decisions

Ask one question at a time, prefer multiple-choice. After each user response:
- Append a `### Q<n>: <summary>` block to the decision log:
  ```
  ### Q<n>: <one-line question summary>
  **Options Presented:** <A/B/C list with one-line each>
  **Decision:** <chosen option>
  **Rationale:** <user rationale or recommended default accepted>
  **Timestamp:** <now>
  ```
- Update `Last Updated`.

Continue until you can write the spec. Indicators you are done with Phase A:
- All architectural decisions are made (you would not need to ask the user again before producing a draft).
- Goals, Non-Goals, Design Principles are settled.
- All ambiguities flagged in early questions are resolved.

## Step 4: Phase A → Phase B transition

Compile an "Alignment Summary" — bullet list of every decision made in Phase A. Append to the decision log:

```
### Phase A → B Transition Confirmation [<timestamp>]
**Alignment Summary (compiled by ds):**
- Decision 1: ...
- Decision 2: ...

**User Confirmation:** <to be filled>
```

Show the summary to the user. They either confirm (set `User Confirmation: ✓ Confirmed`) or request more alignment (set `User Confirmation: Needs more — back to Phase A Q<n+1>`).

If they request more, go back to Step 3. Only after `✓ Confirmed` do you proceed.

Update the file: `Current Phase: spec_writing`.

## Step 5: Sample matching (before writing the draft)

Read `samples/specs/INDEX.md`. Semantically match the current task against each entry's metadata.
- Select up to 2 most relevant samples.
- Tell the user: "Selected sample(s) `<filenames>` as references because <reason>. Proceeding."
- If the user objects, accept overrides (different sample, no sample, etc.).
- If 0 samples are selected (no good matches), record this; the multi-reviewer subsystem will run with 4 reviewers only.

Load the chosen samples' full content into your context.

## Step 6: Write the initial spec draft

Write `docs/superpowers/specs/<today>-<topic-slug>-design.md` from scratch. Use the Alignment Summary as your input. Use the matched samples as structural references.

The spec should contain: Problem, Goals, Non-Goals, Design Principles, Design (with subsections per major component), Implementation Phases, Testing Strategy, File Inventory, Out of Scope. Adjust to suit the topic.

After writing, update the decision log's Phase B Spec Writing Status: `[✓] Initial draft complete (time: <now>)`. Update `Current Phase: review_round_1`.

## Step 7: Multi-reviewer loop

Invoke `superpowers:multi-reviewer`. Pass:
- The draft (the spec file you just wrote).
- The matched samples (0–2) so exemplar-matcher reviewers can be dispatched, one per sample.
- The decision-log file path so the subsystem can update Receipt Status, Findings table, Arbiter Output, and Appendix.

The multi-reviewer SKILL handles the loop, the parallel dispatch, the arbiter, the revisions, and the user-arbitration handoff. When it returns:
- `STOP_CONVERGED` → continue to Step 8.
- `STOP_DEGENERATE` or `STOP_LIMIT` with unresolved → user-arbitration was completed within the subsystem; continue to Step 8 once all unresolved findings have a USER_REJECTED / USER_DEFERRED / FIXED disposition.

Update the file: `Current Phase: finalizing`.

## Step 8: Spec self-review (the inline check the agent runs)

Before showing the spec to the user for sign-off, do a fresh-eyes pass:
1. **Placeholder scan** — any TBD, TODO, unfilled sections? Fix inline.
2. **Internal consistency** — do sections contradict each other?
3. **Scope check** — is this still focused enough for a single implementation plan, or has it bloated?
4. **Ambiguity check** — could any requirement be interpreted two ways? Pick one and make it explicit.

Fix any issues inline. No need to re-run multi-reviewer for these (they are owner-eye nits, not blocking).

## Step 9: User sign-off and commit

Show the spec to the user: "Spec written at `<spec path>`. Please review and either approve or request specific changes."

If the user requests changes, treat them as a tiny new round: revise the spec, append the changes as decisions in the decision log (under a new "Post-Review User Revisions" section), then re-present.

When the user approves:
1. Update the decision log:
   - `Status: Done`
   - `Current Phase: finalizing` (stays)
   - `Final Spec: <spec path>`
   - `Last Updated: <now>`
2. Commit both the spec and the decision log:
   ```bash
   git add docs/superpowers/specs/<spec-filename>.md docs/superpowers/brainstorms/<decision-log-filename>.md
   git commit -m "feat(spec): <topic>"
   ```

## Step 10: Hand off to writing-plans

After commit, tell the user: "Spec committed at `<path>`. Ready to move to implementation planning? I can invoke writing-plans now."

If the user agrees, invoke `superpowers:writing-plans`. Do not invoke any other implementation skill.

## Abandonment

If at any point the user wants to abandon:
1. Update the decision log: `Status: Abandoned`
2. Append:
   ```
   ## Abandonment
   **Timestamp:** <now>
   **Reason:** <user reason>
   ```
3. `git add` + `git commit -m "abandon brainstorm: <topic>"`

## Anti-patterns

- "This is simple, skip Phase A." Every project goes through Phase A. The decision log can be short, but it must exist.
- "I'll write the spec without the multi-reviewer loop because it looks fine." No. The loop is the design.
- "I'll commit the decision log every round to keep things safe." No. Only Status terminal state commits. The file is on disk for visibility; git is for finished artifacts.
- "I'll skip the sample matching, the samples library is small." No. Even 0 matches is an outcome that must be recorded; it changes the reviewer dispatch count.

## Visual companion (preserved)

The `visual-companion.md` and `scripts/` from the previous version of this SKILL remain available. They are unrelated to the multi-reviewer changes; offer them when topics will benefit from mockups, diagrams, or comparisons. The offer must be its own message — see `visual-companion.md` for details.

## Files referenced

- `superpowers:resume-brainstorming` (mandatory first step)
- `superpowers:multi-reviewer` (Phase B review loop)
- `samples/specs/INDEX.md` and any sample file selected
- `docs/superpowers/brainstorms/<filename>-brainstorm.md` (the decision log)
- `docs/superpowers/specs/<filename>-design.md` (the produced spec)
- `./visual-companion.md` (optional, when visual aids will help)
```

- [ ] **Step 2: Self-check structure**

Verify the rewritten SKILL contains:
- Frontmatter.
- HARD-GATE preserving "no implementation until spec sign-off".
- Step 0 invoking resume-brainstorming as strict first step.
- Phase A questions with decision-log append loop.
- Phase A → B transition with user confirmation gate.
- Sample matching step (Step 5).
- Multi-reviewer invocation (Step 7).
- Self-review (Step 8).
- Sign-off + commit (Step 9) with both files committed together.
- Handoff to writing-plans (Step 10).
- Abandonment procedure.
- Visual companion preserved.

- [ ] **Step 3: Commit**

```bash
git add skills/brainstorming/SKILL.md
git commit -m "refactor(brainstorming): rewrite for two-phase + multi-reviewer

Major changes:
- Phase A (alignment) is explicit; Phase A→B transition requires user
  confirmation of the Alignment Summary
- Phase B (spec writing) integrates sample matching, the multi-reviewer
  subsystem, and decision-log status tracking
- Decision-log file written from session start, appended at every step,
  and committed only at terminal state (Done or Abandoned)
- resume-brainstorming is the mandatory Step 0
- visual-companion preserved unchanged"
```

---

### Task 3.2: Delete `brainstorming/spec-document-reviewer-prompt.md`

The previous single-reviewer prompt is replaced by the multi-reviewer subsystem.

**Files:**
- Delete: `skills/brainstorming/spec-document-reviewer-prompt.md`

- [ ] **Step 1: Delete the file**

```bash
git rm skills/brainstorming/spec-document-reviewer-prompt.md
```

- [ ] **Step 2: Commit**

```bash
git commit -m "refactor(brainstorming): remove single-reviewer prompt

The spec-document-reviewer-prompt.md was the previous single-reviewer
mechanism. It is superseded by the multi-reviewer subsystem with 4–6
reviewers and an arbiter. brainstorming/SKILL.md now invokes
superpowers:multi-reviewer for Phase B review."
```

---

## Phase 4: Refactor `writing-plans`

### Task 4.1: Rewrite `writing-plans/SKILL.md`

Full rewrite. Resume-planning is the strict first step. Sample matching, draft, multi-reviewer loop, self-review, sign-off, commit — same shape as the refactored brainstorming, minus Phase A (no alignment phase; a Done spec is the input).

**Files:**
- Modify: `skills/writing-plans/SKILL.md` (full rewrite)

- [ ] **Step 1: Replace the entire file contents**

```markdown
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
```

- [ ] **Step 2: Self-check structure**

Verify the rewritten SKILL contains:
- Frontmatter.
- Step 0 invoking resume-planning as strict first step.
- Source spec made mandatory via resume-planning's design (already enforced upstream).
- Sample matching (Step 3).
- Plan draft with header template, task structure, TDD rhythm, no-placeholder rule (Step 4).
- Multi-reviewer invocation (Step 5).
- Self-review (Step 6).
- Sign-off + commit of both files together (Step 7).
- Execution handoff offering both Subagent-Driven and Inline (Step 8).
- Abandonment procedure.

- [ ] **Step 3: Commit**

```bash
git add skills/writing-plans/SKILL.md
git commit -m "refactor(writing-plans): rewrite for multi-reviewer + plan-progress

Major changes:
- resume-planning is the mandatory Step 0
- Single-phase flow (no alignment; a Done spec is the input)
- Sample matching against samples/plans/INDEX.md
- Multi-reviewer subsystem invoked after draft (Step 5)
- plan-progress file written from session start; Status terminal
  state commits only
- Existing TDD rhythm, no-placeholder rule, header template preserved
- Execution handoff preserved (Subagent-Driven recommended, Inline alt)"
```

---

### Task 4.2: Delete `writing-plans/plan-document-reviewer-prompt.md`

**Files:**
- Delete: `skills/writing-plans/plan-document-reviewer-prompt.md`

- [ ] **Step 1: Delete the file**

```bash
git rm skills/writing-plans/plan-document-reviewer-prompt.md
```

- [ ] **Step 2: Commit**

```bash
git commit -m "refactor(writing-plans): remove single-reviewer prompt

Superseded by superpowers:multi-reviewer."
```

---

## Phase 5: End-to-End Validation

These tasks run real sessions and observe the system's behavior against the 14 spec scenarios. They are manual tests; no test framework executes them. Each task is "drive a session, observe, document". If any task fails, fix the underlying issue (in the relevant SKILL or prompt file) and re-run the task.

### Task 5.1: Brainstorming end-to-end (T1, T2, T3, T4, T8)

Run multiple brainstorming sessions to exercise the main flow paths.

**Scenarios:**
- T1: full success path — Phase A → B → convergence → Done
- T2: user rejects a finding via the user-arbitration handoff (test the `USER_REJECTED(I<n>)` flow)
- T3: artificially induce STOP_DEGENERATE (set up reviewers to find new things each round; observe the 50% degradation gate trip)
- T4: artificially extend the loop to 3 rounds with sufficient findings to never hit STOP_CONVERGED (observe STOP_LIMIT)
- T8: start a session, then abandon it (observe Status → Abandoned commit and the appended Abandonment block)

- [ ] **Step 1: Run T1 — full success path**

Choose a small real topic ("Make a tiny helper script that prints hostname"). Run brainstorming end-to-end.

Verify:
- `resume-brainstorming` invoked at start (look for the announcement).
- Decision log created; metadata filled; Q&A appended one per question.
- Phase A → B transition explicit, with Alignment Summary and user confirmation recorded.
- Sample matching invoked (likely 0 hits for a tiny script; record this).
- Multi-reviewer invoked; either 4 reviewers (if 0 samples) or 5–6 (if any).
- Arbiter output captured in the decision log with explicit convergence_status.
- Loop converges to STOP_CONVERGED.
- Self-review runs.
- User sign-off; Status → Done; commit includes both the spec and the decision log.

If any step is missing or misbehaves, fix the SKILL responsible and re-run.

- [ ] **Step 2: Run T2 — user rejects a finding**

Run a session up to the multi-reviewer loop. When a real (not synthetic) IMPORTANT finding appears that the user disagrees with, drive the loop until STOP_DEGENERATE or STOP_LIMIT (or use a small spec where that finding survives to the user-arbitration handoff). Reject the finding; verify the decision log records `I<n>` with the user's rationale, and the finding's Status becomes `USER_REJECTED(I<n>)`.

- [ ] **Step 3: Run T3 — induce STOP_DEGENERATE**

Brainstorm a small but flawed spec (intentionally vague, with deliberate gaps). Observe that reviewers find many things round 1 and continue finding new things round 2 at a rate not below 50% of round 1's count. Verify the arbiter sets `degradation_check: FAILED` and `convergence_status: STOP_DEGENERATE`, and that the user-arbitration handoff triggers with the unresolved findings.

- [ ] **Step 4: Run T4 — hit STOP_LIMIT**

Brainstorm a complex spec that converges slowly. Force the loop to complete 3 rounds without reaching `current_effective == 0` and without tripping degradation (each round must have current_effective ≤ 50% of prev_total). Verify the arbiter declares `STOP_LIMIT` and the user-arbitration handoff handles unresolved items.

- [ ] **Step 5: Run T8 — abandon mid-session**

Start a brainstorming session. After at least one Q&A, tell the agent to abandon. Verify:
- The decision log's Status flips to Abandoned.
- An Abandonment block is appended (timestamp + reason).
- A commit was made with message starting `abandon brainstorm:`.

- [ ] **Step 6: Document scenarios in the plan-progress (this Phase 5 task)**

In this very plan's plan-progress file (if we are dogfooding), or in a separate scratch document if not, summarize the observed behavior for T1–T4 and T8. Note any deviations and the fixes applied.

(No commit for this task itself; commits happen inside the scenarios as the SKILLs trigger them.)

---

### Task 5.2: Brainstorming resume scenarios (T5, T6, T7)

**Scenarios:**
- T5: mid-session interruption + resume continues from the recorded Current Phase
- T6: start a new session based on a Done file (Based On preserves prior content as context)
- T7: start a new session based on an Abandoned file (Based On + abandonment rationale surfaced)

- [ ] **Step 1: Run T5 — interrupt and resume**

For each value of Current Phase (alignment, spec_writing, review_round_N, awaiting_user_decision, finalizing):
- Start a brainstorming session and drive it until Current Phase reaches that value.
- Close the session (effectively interrupt — do not commit).
- Start a new brainstorming session. Verify `resume-brainstorming` finds the In Progress file, presents it in the menu, and on user choice "1" resumes from the recorded Current Phase per the recovery table.

If any phase fails to resume correctly, fix the resume-brainstorming SKILL or the brainstorming SKILL and re-run.

- [ ] **Step 2: Run T6 — based on Done**

After at least one brainstorming session has reached Done, start a new session. Choose option B (new based on the Done file). Verify:
- A new file is created in `docs/superpowers/brainstorms/`.
- Header contains `Based On: <Done filename>`.
- The agent demonstrates awareness of the prior discussion (reference it in its first Q or its design choices).

- [ ] **Step 3: Run T7 — based on Abandoned**

Same as T6 but choose option C against an Abandoned file. Additionally verify the agent surfaces the abandonment reason to the user before resuming.

---

### Task 5.3: writing-plans end-to-end and resume (T9, T10)

**Scenarios:**
- T9: writing-plans end-to-end → Done (using a Done spec from Task 5.1)
- T10: writing-plans resume from each Current Phase (draft_writing, review_round_N, awaiting_user_decision, finalizing)

- [ ] **Step 1: Run T9 — end-to-end planning**

Pick a Done spec from Task 5.1's runs. Invoke writing-plans. Verify:
- `resume-planning` invoked at start.
- Source spec selection enforced; chosen spec is the one from Task 5.1.
- Plan-progress file created with required metadata including `Source Spec`.
- Sample matching against `samples/plans/INDEX.md` runs.
- Draft written with required header, task structure, TDD steps.
- Multi-reviewer loop runs and converges.
- Self-review runs (spec coverage, placeholder scan, type consistency).
- User sign-off; commit includes plan + plan-progress.
- Execution handoff offered.

- [ ] **Step 2: Run T10 — planning resume**

For each Current Phase value (draft_writing, review_round_N, awaiting_user_decision, finalizing):
- Drive a writing-plans session until Current Phase reaches that value.
- Interrupt.
- Start a new writing-plans session for the same source spec. Verify resume-planning finds it, presents it, and on "1" resumes correctly.

---

### Task 5.4: Sample library scenarios (T11, T12, T13, T14)

**Scenarios:**
- T11: initialization (managing-samples Workflow 1)
- T12: single promotion (managing-samples Workflow 2)
- T13: conflict scan correctly detects an artificial conflict
- T14: 0 / 1 / 2 sample matches each correctly drive reviewer count to 4 / 5 / 6

- [ ] **Step 1: Run T11 — initialization**

Task 1.5 of this plan already does this once. Re-run only if Task 1.5 had to be redone. Verify:
- All 5 specs and 5 plans copied to `samples/`.
- INDEX.md files populated with valid YAML entries.
- Single commit was made by the SKILL with message starting `feat(samples): seed initial sample library`.

- [ ] **Step 2: Run T12 — single promotion**

After at least one brainstorming session has produced a new spec (Task 5.1 T1), ask the agent: "Add `docs/superpowers/specs/<that-spec>.md` as a sample." Verify:
- managing-samples Workflow 2 runs.
- Metadata is recommended; user can edit.
- Conflict scan runs against existing entries.
- File copied to `samples/specs/`; INDEX entry appended.
- Single commit `feat(samples): add <topic> as exemplar`.

- [ ] **Step 3: Run T13 — conflict detection**

Hand-craft a candidate INDEX entry that conflicts with an existing entry (same `problem_summary`, opposing `characteristics`). Ask the agent to add the new sample. Verify:
- The conflict scan identifies the pair as CONFLICT (not NONE).
- The three-way menu is presented.
- Each of the three resolutions is achievable: choose "keep new, delete old" and verify deletion + replacement happens; restart with a fresh duplicate and try the other two options.

- [ ] **Step 4: Run T14 — reviewer count by sample hits**

Run brainstorming three times against three different topics chosen so that:
- One topic produces 0 sample matches (verify only 4 reviewers dispatch).
- One topic produces 1 sample match (verify 5 reviewers including 1 exemplar-matcher).
- One topic produces 2 sample matches (verify 6 reviewers including 2 exemplar-matchers, each with its own assigned sample).

Inspect the decision log's "Dispatched reviewers" line for each run to confirm.

---

### Task 5.5: Dogfooding — brainstorm Spec B with the new flow

Use the newly refactored brainstorming SKILL to brainstorm and produce **Spec B (Ability Self-Evolution System)**. This is the most credible acceptance test: the new SKILL is doing real work, on a non-trivial spec, end-to-end.

**Files:**
- Create (via brainstorming session): `docs/superpowers/brainstorms/<today>-spec-b-ability-self-evolution-brainstorm.md`
- Create (via brainstorming session): `docs/superpowers/specs/<today>-spec-b-ability-self-evolution-design.md`

- [ ] **Step 1: Invoke brainstorming with the Spec B topic**

Start a brainstorming session. Stated topic: "능력 자진화 시스템 (Spec B): lessons-learned + 剪枝 + 角색-classified access. Depends on this fork's multi-reviewer + decision-log infrastructure already being in place."

Drive the session end-to-end:
- Phase A questions cover the design dimensions (lessons data structure, reflection agent design, pruning triggers, role-classification access, write/read timing, conflict with reviewer/implementer, safety controls).
- Phase A → B transition with Alignment Summary confirmed.
- Sample matching (likely matches this Spec A's design as a sample, since it is structurally similar).
- Multi-reviewer loop converges.
- Self-review and sign-off.

- [ ] **Step 2: Confirm acceptance**

Verify all of the following held throughout the session:
- The decision log file exists, is populated, and was committed only at Done.
- The multi-reviewer subsystem dispatched the correct number of reviewers (with at least one exemplar-matcher, since this Spec A is a strong structural match).
- Convergence occurred under the configured rules (no infinite loop, no silent skip).
- The produced Spec B is coherent and ready for its own writing-plans run.

If any of the above failed, the test fails; root-cause the SKILL responsible and fix.

- [ ] **Step 3: Commit (only if the session itself did not already)**

The brainstorming SKILL commits at sign-off in its own Step 9. No additional commit needed here unless dogfooding revealed file-level bugs that required fixing — in that case, those fixes were separate commits.

---

## Self-Review (run after the plan is written, before the user reviews)

This is the inline self-review the writing-plans SKILL prescribes. Done as part of this plan's authoring.

### Spec coverage check

Going section by section through the spec:

- Section A (multi-reviewer subsystem) → Tasks 1.6–1.14 cover finding-schema, convergence-rules, arbiter-prompt, 5 reviewer prompts, SKILL.md. ✓
- Section B (samples library + managing-samples SKILL) → Tasks 1.1–1.5 cover library skeleton, schema, conflict-detection prompt, SKILL.md, and seeding. ✓
- Section C (decision log) → Task 2.2 creates the template; Task 3.1 wires brainstorming to write it. ✓
- Section D (plan-progress) → Task 2.4 creates the template; Task 4.1 wires writing-plans to write it. ✓
- Section E (resume SKILLs) → Tasks 2.3, 2.5. ✓
- Section F (refactor brainstorming and writing-plans) → Tasks 3.1, 3.2, 4.1, 4.2. ✓
- Implementation Phases → Phase 1 = Tasks 1.x; Phase 2 = Tasks 2.x; Phase 3 = Tasks 3.x; Phase 4 = Tasks 4.x; Phase 5 = Tasks 5.x. ✓
- Testing Strategy → Tasks 5.1–5.5 cover all 14 behavior scenarios (T1–T14) plus dogfooding. ✓
- File Inventory → Tasks together produce every file in the inventory table; no orphans. ✓
- Out of Scope → not implemented (correctly). ✓

No spec requirements remain unmapped.

### Placeholder scan

Searched this plan for: TBD, TODO, "implement later", "similar to Task N", "fill in details", undefined references.
- No TBD / TODO / "implement later" present.
- No "similar to" present.
- All referenced files (templates, prompts, SKILLs) are defined in some task.
- All file paths are concrete.

### Type / name consistency

- "decision log" / "brainstorm decision log" — consistent terminology throughout.
- "plan-progress" / "*-plan-progress.md" — consistent.
- Reviewer roles: architect, red-team, edge-cases, yagni-gatekeeper, exemplar-matcher — same names in every task.
- Convergence statuses: STOP_CONVERGED, STOP_DEGENERATE, STOP_LIMIT, CONTINUE — same in every task.
- Status / Arbiter / Sev enum values match across Task 1.6 (schema), Task 1.8 (arbiter), Task 2.2 / 2.4 (templates), and Tasks 3.1 / 4.1 (SKILL invocations).
- `Current Phase` allowed values: brainstorm has 5 (alignment, spec_writing, review_round_N, awaiting_user_decision, finalizing); plan-progress has 4 (no alignment). Consistent.

No naming inconsistencies found.

### Closing note

This plan is comprehensive. Phase 1 alone is 14 substantial tasks; the cumulative SKILL/prompt content is large because the system is largely text-based. Real iteration is expected once Phase 5 runs reveal misbehaviors that prose-only review missed. That is the design intent: the dogfooding loop (Task 5.5) is the most credible test we can run.
