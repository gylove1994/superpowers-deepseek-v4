# Spec & Plan TDD/BDD Independent Review Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-deepseek-v4:subagent-driven-development (recommended) or superpowers-deepseek-v4:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `bdd-reviewer` and `tdd-reviewer` as fixed multi-reviewer roles with Gherkin acceptance criteria, layered TDD enforcement, and updated SKILL/template integration — shipped atomically in one release.

**Architecture:** Phase 1 updates `brainstorming`, `writing-plans`, and file templates so drafts include Acceptance Scenarios / Acceptance Criteria before review. Phase 2 (same PR) adds two reviewer prompt files and extends `multi-reviewer/` (SKILL, convergence-rules, finding-schema, arbiter-prompt, exemplar-matcher). All verification is structure self-check or agent behavior-test — no application code, no invented test commands.

**Tech Stack:** Markdown SKILL files, YAML finding schema, parallel Task subagent dispatch

**Spec:** `docs/superpowers/specs/2026-05-21-spec-plan-tdd-bdd-review-design.md`

---

## File Map

| Action | Path |
|--------|------|
| Modify | `skills/brainstorming/SKILL.md` |
| Modify | `skills/writing-plans/SKILL.md` |
| Modify | `skills/resume-brainstorming/templates/brainstorm-template.md` |
| Modify | `skills/resume-planning/templates/plan-progress-template.md` |
| Modify | `skills/using-superpowers/SKILL.md` |
| Create | `skills/multi-reviewer/reviewer-prompts/bdd-reviewer.md` |
| Create | `skills/multi-reviewer/reviewer-prompts/tdd-reviewer.md` |
| Modify | `skills/multi-reviewer/finding-schema.md` |
| Modify | `skills/multi-reviewer/SKILL.md` |
| Modify | `skills/multi-reviewer/convergence-rules.md` |
| Modify | `skills/multi-reviewer/arbiter-prompt.md` |
| Modify | `skills/multi-reviewer/reviewer-prompts/exemplar-matcher.md` |

**Release gate (spec §Implementation Phases):** Commit Phase 1 tasks before Phase 2 tasks in the same PR; do not merge partial Phase 2 without Phase 1.

---

## Chunk 1: Template & SKILL Integration (Phase 1)

### Task 0: Update resume templates — six reviewers + Round N metadata

**Files:**
- Modify: `skills/resume-brainstorming/templates/brainstorm-template.md`
- Modify: `skills/resume-planning/templates/plan-progress-template.md`

**Acceptance Criteria:**

Feature: Decision-log template lists six fixed reviewers
  Scenario: Plan-progress template Round 1 dispatch line
    Given plan-progress-template.md on disk
    When grep searches Dispatched reviewers line
    Then output includes bdd-reviewer and tdd-reviewer

- [ ] **Step 1: Edit brainstorm-template.md Round 1 dispatched line** — replace `architect | red-team | edge-cases | yagni-gatekeeper` with `architect | red-team | edge-cases | yagni-gatekeeper | bdd-reviewer | tdd-reviewer [| exemplar-matcher ...]`.

- [ ] **Step 2: Edit plan-progress-template.md** — same dispatched line update; add after Receipt Status block:

```markdown
**Receipt Status:** architect ⏳ | red-team ⏳ | edge-cases ⏳ | yagni-gatekeeper ⏳ | bdd-reviewer ⏳ | tdd-reviewer ⏳ [| exemplar-matcher ⏳ ...]  (states: ⏳ waiting | ✓ | ✗ failed)

**Round metadata:** dispatched_count: | successful_receipt_count: | excluded_roles:
```

- [ ] **Step 2b: Edit brainstorm-template.md Round 1** — add the same **Round metadata:** block and Receipt Status states line as in plan-progress-template.

- [ ] **Step 3: Add hints** — brainstorm-template: `Spec drafts must include ## Acceptance Scenarios (Gherkin) after Design Principles.` plan-progress-template: `Plan tasks must include **Acceptance Criteria:** (Gherkin) per writing-plans Step 4.`

- [ ] **Step 4: Structure self-check**

```bash
grep "bdd-reviewer" skills/resume-brainstorming/templates/brainstorm-template.md skills/resume-planning/templates/plan-progress-template.md
grep "excluded_roles" skills/resume-planning/templates/plan-progress-template.md
```

Expected: bdd-reviewer in both; excluded_roles in plan-progress template.

- [ ] **Step 5: Commit**

```bash
git add skills/resume-brainstorming/templates/brainstorm-template.md skills/resume-planning/templates/plan-progress-template.md
git commit -m "$(cat <<'EOF'
feat(templates): six-reviewer dispatch and round metadata slots

EOF
)"
```

---

### Task 1: Update brainstorming SKILL — Acceptance Scenarios + six reviewers

**Files:**
- Modify: `skills/brainstorming/SKILL.md`

**Acceptance Criteria:**

Feature: Brainstorming spec structure includes Acceptance Scenarios
  Scenario: Step 6 lists Acceptance Scenarios placement
    Given brainstorming SKILL.md on disk
    When grep searches Step 6 section list
    Then output includes Acceptance Scenarios after Design Principles before Design

- [ ] **Step 1: Structure self-check** — read current Step 6 (line ~92–98); confirm it lists sections without Acceptance Scenarios and mentions "4 reviewers only" at Step 5 (~line 88).

- [ ] **Step 2: Edit Step 5 sample-matching note** — replace `4 reviewers only` with `6 fixed reviewers (plus 0–2 exemplar-matchers)` in both occurrences (Step 5 and anti-patterns if present).

- [ ] **Step 3: Edit Step 6 spec section list** — replace the section list paragraph with:

```markdown
The spec should contain, in order: Problem, Goals, Non-Goals, Design Principles, **Acceptance Scenarios** (Gherkin Feature/Scenario/Given/When/Then blocks — mandatory, placed here), Design (with subsections per major component), Implementation Phases, Testing Strategy, File Inventory, Out of Scope. Adjust subsection depth to suit the topic; do not omit Acceptance Scenarios.
```

- [ ] **Step 4: Structure self-check** — run:

```bash
grep -n "Acceptance Scenarios" skills/brainstorming/SKILL.md
grep -n "6 fixed reviewers" skills/brainstorming/SKILL.md
```

Expected: both greps return ≥1 match; no line contains `4 reviewers only`.

- [ ] **Step 5: Commit**

```bash
git add skills/brainstorming/SKILL.md
git commit -m "$(cat <<'EOF'
feat(brainstorming): require Acceptance Scenarios and six fixed reviewers

EOF
)"
```

---

### Task 2: Update writing-plans SKILL — Acceptance Criteria + six reviewers

**Files:**
- Modify: `skills/writing-plans/SKILL.md`

**Acceptance Criteria:**

Feature: Writing-plans task template includes Acceptance Criteria
  Scenario: Step 4 documents Gherkin per task
    Given writing-plans SKILL.md on disk
    When grep searches for Acceptance Criteria in Step 4
    Then output includes Acceptance Criteria with Gherkin Scenario requirement

- [ ] **Step 1: Structure self-check** — read Step 3 (~line 48) and Step 4 (~lines 75–80); confirm `4 reviewers only` and no Acceptance Criteria requirement.

- [ ] **Step 2: Edit Step 3** — replace `4 reviewers only` with `6 fixed reviewers (plus 0–2 exemplar-matchers)`.

- [ ] **Step 3: Edit Step 4 task structure bullet list** — after the **Files:** bullet, add:

```markdown
  - **Acceptance Criteria:** (mandatory per task) at least one Gherkin Scenario block:
    ```markdown
    **Acceptance Criteria:**

    Feature: <task-scoped feature>
      Scenario: <verifiable outcome>
        Given <precondition>
        When <action>
        Then <observable outcome>
    ```
    Outcome criteria here; TDD steps below describe process. Both required for tasks that modify files.
```

- [ ] **Step 4: Paste spec §E normative example** — add to Step 4 after the Acceptance Criteria bullet block (paste verbatim from source spec §E skill-only task example).

- [ ] **Step 4b: Add skill-only vs code task note** — append:

```markdown
  - For skill/prompt tasks: structure self-check or behavior-test (no invented npm test). For code tasks: RED → run-to-fail → GREEN → run-to-pass. Mixed tasks: code steps first, skill verification second (spec §C.5).
```

- [ ] **Step 5: Structure self-check**

```bash
grep -n "Acceptance Criteria" skills/writing-plans/SKILL.md
grep -n "6 fixed reviewers" skills/writing-plans/SKILL.md
```

Expected: Acceptance Criteria in Step 4; six fixed reviewers in Step 3; no `4 reviewers only`.

- [ ] **Step 6: Commit**

```bash
git add skills/writing-plans/SKILL.md
git commit -m "$(cat <<'EOF'
feat(writing-plans): require per-task Gherkin Acceptance Criteria

EOF
)"
```

---

## Chunk 2: New Reviewer Prompts (Phase 2)

### Task 3: Create bdd-reviewer prompt

**Files:**
- Create: `skills/multi-reviewer/reviewer-prompts/bdd-reviewer.md`

**Acceptance Criteria:**

Feature: bdd-reviewer prompt exists with dual checklists
  Scenario: Prompt file has spec-draft and plan-draft sections
    Given bdd-reviewer.md on disk
    When grep searches for document_type is spec-draft and plan-draft
    Then both section headers exist

- [ ] **Step 1: Create file** — write `skills/multi-reviewer/reviewer-prompts/bdd-reviewer.md` with this content (copy checklists verbatim from source spec §B):

```markdown
# BDD Reviewer

You are the **bdd-reviewer** in the multi-reviewer subsystem. You enforce strict Gherkin (Feature/Scenario/Given/When/Then; `And` allowed). Keywords in English; step text may match draft language.

## Inputs

- `draft` — full spec or plan text
- `document_type` — `spec-draft` or `plan-draft` (injected by controller preamble)
- For `plan-draft` only: `source_spec_path` + full source spec text (read-only, for legacy traceability when source has Acceptance Scenarios)

## What you do NOT look at

- TDD step ordering (tdd-reviewer)
- Architecture (architect)
- Scope creep (yagni-gatekeeper)
- Test framework choice (tdd-reviewer)

## When document_type is spec-draft

Apply source spec §B.1 checklist:

| Category | Severity |
|----------|----------|
| Goals non-empty | BLOCKING if empty |
| `## Acceptance Scenarios` exists | BLOCKING if missing |
| Section after Design Principles, before Design | BLOCKING if elsewhere |
| ≥1 Scenario block (not header-only) | BLOCKING if empty |
| Gherkin structure per scenario | BLOCKING if malformed |
| Every Goal has ≥1 demonstrating scenario | BLOCKING if uncovered |
| Observable Then clauses | IMPORTANT if vague |
| Failure path when Goals imply error handling | IMPORTANT if absent |

## When document_type is plan-draft

Apply source spec §B.2 checklist:

| Category | Severity |
|----------|----------|
| Every `### Task N:` has `**Acceptance Criteria:**` with ≥1 Gherkin scenario | BLOCKING if missing |
| Spec traceability when source has Acceptance Scenarios | IMPORTANT if orphan |
| Legacy source spec without Acceptance Scenarios | skip traceability IMPORTANT |
| Then describes outcome not process-only | BLOCKING if process-only |

## Output format

Emit YAML per `../finding-schema.md`. Set `reviewer_role: bdd-reviewer`. Max 3 NITs.

```yaml
findings: []
NO_BLOCKING_ISSUES: true
```

when clean.
```

- [ ] **Step 2: Structure self-check**

```bash
test -f skills/multi-reviewer/reviewer-prompts/bdd-reviewer.md && grep -c "spec-draft" skills/multi-reviewer/reviewer-prompts/bdd-reviewer.md
```

Expected: file exists; grep count ≥ 1.

- [ ] **Step 3: Commit**

```bash
git add skills/multi-reviewer/reviewer-prompts/bdd-reviewer.md
git commit -m "$(cat <<'EOF'
feat(multi-reviewer): add bdd-reviewer prompt

EOF
)"
```

---

### Task 4: Create tdd-reviewer prompt

**Files:**
- Create: `skills/multi-reviewer/reviewer-prompts/tdd-reviewer.md`

**Acceptance Criteria:**

Feature: tdd-reviewer prompt exists with layered task rules
  Scenario: Prompt references mixed-task order
    Given tdd-reviewer.md on disk
    When grep searches for mixed or C.5
    Then output references code steps before skill verification

- [ ] **Step 1: Create file** — write `skills/multi-reviewer/reviewer-prompts/tdd-reviewer.md`:

```markdown
# TDD Reviewer

You are the **tdd-reviewer** in the multi-reviewer subsystem. You enforce test-first discipline appropriate to task type.

## Inputs

- `draft` — full spec or plan text
- `document_type` — `spec-draft` or `plan-draft`
- For `plan-draft`: `source_spec_path` + full text of source spec `## Testing Strategy` section (read-only)

## References (read-only)

- `skills/test-driven-development/SKILL.md`
- `skills/writing-plans/SKILL.md`
- `skills/writing-skills/testing-skills-with-subagents.md`

## What you do NOT look at

- Gherkin formatting (bdd-reviewer)
- Goal coverage in scenarios (bdd-reviewer)
- Architecture (architect)

## When document_type is spec-draft

Apply source spec §C.1:

| Category | Severity |
|----------|----------|
| `## Testing Strategy` exists and non-empty | BLOCKING if missing |
| Test-first principle for code changes | IMPORTANT if absent |
| Concrete verification commands or behavior-test protocol | BLOCKING if vague |
| Structure self-check / behavior-test for skill changes | IMPORTANT if spec touches skills and omits |

## When document_type is plan-draft — code tasks

Trigger: Task **Files** includes source-code extension (`.ts`, `.js`, `.py`, etc.).

Apply §C.2: RED step, run-to-fail, GREEN, run-to-pass, order — all BLOCKING if missing or reversed.

Plan task verification must not contradict source spec Testing Strategy — BLOCKING if contradicts.

## When document_type is plan-draft — non-code tasks

Trigger: SKILL.md, prompt templates, docs only.

Apply §C.3: structure self-check OR behavior-test — BLOCKING if neither; pass criteria — BLOCKING if vague; fake unit tests — IMPORTANT.

## Mixed code + skill tasks (§C.5)

When Files lists both code and skill paths: code RED/GREEN group first, skill verification second, commit last. Apply §C.2 to code steps, §C.3 to skill steps. Do not emit BLOCKING solely because skill verification steps appear after code steps across groups.

## Output format

YAML per `../finding-schema.md`. `reviewer_role: tdd-reviewer`. Max 3 NITs. Emit `NO_BLOCKING_ISSUES: true` when clean.
```

- [ ] **Step 2: Structure self-check**

```bash
test -f skills/multi-reviewer/reviewer-prompts/tdd-reviewer.md && grep "Mixed code" skills/multi-reviewer/reviewer-prompts/tdd-reviewer.md
```

Expected: file exists; Mixed code section found.

- [ ] **Step 3: Commit**

```bash
git add skills/multi-reviewer/reviewer-prompts/tdd-reviewer.md
git commit -m "$(cat <<'EOF'
feat(multi-reviewer): add tdd-reviewer prompt

EOF
)"
```

---

## Chunk 3: Multi-Reviewer Subsystem Updates (Phase 2)

### Task 5: Update finding-schema reviewer_role enum

**Files:**
- Modify: `skills/multi-reviewer/finding-schema.md`

**Acceptance Criteria:**

Feature: finding-schema lists bdd and tdd roles
  Scenario: reviewer_role line includes new roles
    Given finding-schema.md on disk
    When grep searches reviewer_role enum line
    Then output contains bdd-reviewer and tdd-reviewer

- [ ] **Step 1: Edit line 13** — change `reviewer_role` enum to:

```markdown
reviewer_role: architect | red-team | edge-cases | yagni-gatekeeper | exemplar-matcher | bdd-reviewer | tdd-reviewer
```

- [ ] **Step 2: Edit line 50** — change `five reviewer prompt files` to `seven reviewer prompt files` and add bdd-reviewer.md and tdd-reviewer.md to the list.

- [ ] **Step 3: Structure self-check**

```bash
grep "bdd-reviewer" skills/multi-reviewer/finding-schema.md
```

Expected: ≥2 matches.

- [ ] **Step 4: Commit**

```bash
git add skills/multi-reviewer/finding-schema.md
git commit -m "$(cat <<'EOF'
feat(multi-reviewer): extend finding-schema for bdd/tdd roles

EOF
)"
```

---

### Task 6: Update multi-reviewer SKILL — dispatch, payload, receipt state machine

**Files:**
- Modify: `skills/multi-reviewer/SKILL.md`

**Acceptance Criteria:**

Feature: Six fixed reviewers dispatched
  Scenario: SKILL dispatch list includes bdd and tdd
    Given multi-reviewer SKILL.md on disk
    When grep searches fixed reviewer list in section 1
    Then bdd-reviewer and tdd-reviewer appear with architect

- [ ] **Step 1: Edit frontmatter description** — change `4 fixed reviewers` to `6 fixed reviewers (architect, red-team, edge-cases, yagni-gatekeeper, bdd-reviewer, tdd-reviewer)`.

- [ ] **Step 2: Replace §1 Compute reviewer dispatch list** with:

```markdown
### 1. Compute reviewer dispatch list

- Always include: `architect`, `red-team`, `edge-cases`, `yagni-gatekeeper`, `bdd-reviewer`, `tdd-reviewer`.
- Plus: one `exemplar-matcher` per matched sample (0, 1, or 2). Total reviewer count is 6, 7, or 8.
```

- [ ] **Step 3: Expand §3 Dispatch** — after existing bullets, add:

```markdown
- **document_type selection:** brainstorming Phase B → `spec-draft`; writing-plans → `plan-draft`. Invalid or missing enum → receipt ✗ failed (re-dispatch once, then exclude per §4).
- Preamble for every reviewer: `document_type` as above.
- For `bdd-reviewer` on plan-draft: include `source_spec_path` + full source spec text.
- For `tdd-reviewer` on plan-draft: include `source_spec_path` + full source spec `## Testing Strategy` section text; if section absent, pass `testing_strategy_absent: true` and tdd-reviewer applies spec §C.1 BLOCKING against source spec.
- Load prompts from `reviewer-prompts/bdd-reviewer.md` and `reviewer-prompts/tdd-reviewer.md`.
```

- [ ] **Step 4: Replace §4 Collect receipts** with:

```markdown
### 4. Collect and validate receipts

For each reviewer output:
1. Validate YAML finding-schema (all required fields; empty findings require `NO_BLOCKING_ISSUES: true`).
2. If invalid, empty, non-YAML, or crash → re-dispatch once with format reminder.
3. Second failure → mark receipt `✗ failed`, exclude from arbiter input, record in decision-log.
4. Valid → mark `✓`.

Record in Round N metadata: `dispatched_count`, `successful_receipt_count`, `excluded_roles`.

If **all** reviewers failed: do not dispatch arbiter; mark round failed; surface to user.

If any fixed reviewer role is in `excluded_roles`: arbiter must not return `STOP_CONVERGED` unless user-arbitration accepts partial round.
```

- [ ] **Step 5: Replace §5 Dispatch the arbiter** with:

```markdown
### 5. Dispatch the arbiter

After receipt validation completes (not merely when subagents return):
- Build `reviewer_outputs` from receipts marked ✓ only.
- If `successful_receipt_count == 0`, skip arbiter; mark round failed in decision-log.
- Dispatch arbiter with: draft, filtered reviewer_outputs, round, prev_total, and round_metadata `{ dispatched_count, successful_receipt_count, excluded_roles }`.
- If any fixed reviewer is in `excluded_roles`, arbiter must not emit STOP_CONVERGED unless decision-log records explicit user acceptance of partial review.
```

- [ ] **Step 6: Update Files referenced** — add bdd-reviewer.md and tdd-reviewer.md.

- [ ] **Step 7: Structure self-check**

```bash
grep -E "bdd-reviewer|tdd-reviewer|Testing Strategy|document_type" skills/multi-reviewer/SKILL.md | head -15
```

Expected: six roles; document_type selection; Testing Strategy payload for plan-draft tdd-reviewer.

- [ ] **Step 8: Commit**

```bash
git add skills/multi-reviewer/SKILL.md
git commit -m "$(cat <<'EOF'
feat(multi-reviewer): dispatch six fixed reviewers with receipt validation

EOF
)"
```

---

### Task 7: Update convergence-rules.md

**Files:**
- Modify: `skills/multi-reviewer/convergence-rules.md`

**Acceptance Criteria:**

Feature: Pseudocode lists six fixed reviewers
  Scenario: fixed_reviewers set includes bdd and tdd
    Given convergence-rules.md on disk
    When grep searches fixed_reviewers in pseudocode block
    Then bdd-reviewer and tdd-reviewer appear

- [ ] **Step 1: Edit pseudocode** — replace `fixed_reviewers={architect, red-team, edge-cases, yagni-gatekeeper}` with six fixed including bdd-reviewer and tdd-reviewer; after `parallel_dispatch` add:

```text
reviewer_outputs = validate_receipts(raw_outputs)  # re-dispatch once; excluded_roles; ✓ only to arbiter
if successful_receipt_count == 0: round_failed; continue LOOP or abort
arbiter(..., reviewer_outputs=successful_only, round_metadata={...})
```

- [ ] **Step 2: Add invalid document_type row** in STOP_CONVERGED guards section matching spec §G.

- [ ] **Step 3: Edit hard ceiling comment** — `six-to-eight parallel reviewers`.

```markdown
## STOP_CONVERGED guards

- If `successful_receipt_count == 0` for a round, do not call arbiter; round status = failed.
- If any fixed reviewer role is in `excluded_roles` for this round, arbiter must not emit `STOP_CONVERGED` unless the decision-log records explicit user acceptance of partial review.
```

- [ ] **Step 4: Structure self-check**

```bash
grep "bdd-reviewer" skills/multi-reviewer/convergence-rules.md
grep "STOP_CONVERGED guards" skills/multi-reviewer/convergence-rules.md
```

Expected: both match.

- [ ] **Step 5: Commit**

```bash
git add skills/multi-reviewer/convergence-rules.md
git commit -m "$(cat <<'EOF'
feat(multi-reviewer): update convergence rules for six reviewers

EOF
)"
```

---

### Task 8: Update arbiter-prompt.md

**Files:**
- Modify: `skills/multi-reviewer/arbiter-prompt.md`

**Acceptance Criteria:**

Feature: Arbiter knows bdd/tdd roles and partial-round guard
  Scenario: Inputs list includes bdd-reviewer and tdd-reviewer
    Given arbiter-prompt.md on disk
    When grep searches reviewer_role list in Inputs section
    Then bdd-reviewer and tdd-reviewer are listed

- [ ] **Step 1: Edit Inputs** — add `| bdd-reviewer | tdd-reviewer` to reviewer_role list; add:

```markdown
- `round_metadata` — `{ dispatched_count, successful_receipt_count, excluded_roles }` from controller (required after Task 6).
- `reviewer_outputs` — successful receipts only (✓), never unvalidated or ✗ failed roles.
```

- [ ] **Step 2: Add Step 3 conflict precedence** — paste verbatim into arbiter-prompt.md Step 3:

```markdown
Role precedence for same location:
- Gherkin format disputes → bdd-reviewer wins over tdd-reviewer.
- TDD step ordering disputes → tdd-reviewer wins over bdd-reviewer.
- Mixed code+skill task ordering → tdd-reviewer §C.5 template wins (no BLOCKING for cross-group order).
```

- [ ] **Step 3: Add STOP_CONVERGED guards** (excluded_roles, successful_receipt_count == 0).

```markdown
Before emitting `STOP_CONVERGED`:
- If controller reports any fixed reviewer in `excluded_roles` for this round, set `convergence_status` to require user-arbitration (treat as STOP_DEGENERATE with partial-round rationale) unless decision-log explicitly records user acceptance of partial review.
- If `successful_receipt_count == 0`, do not emit STOP_CONVERGED.
```

- [ ] **Step 4: Structure self-check**

```bash
grep -E "bdd-reviewer|excluded_roles" skills/multi-reviewer/arbiter-prompt.md
```

Expected: ≥2 matches.

- [ ] **Step 5: Commit**

```bash
git add skills/multi-reviewer/arbiter-prompt.md
git commit -m "$(cat <<'EOF'
feat(multi-reviewer): arbiter bdd/tdd precedence and partial-round guard

EOF
)"
```

---

### Task 9: Update exemplar-matcher for pre-Gherkin samples

**Files:**
- Modify: `skills/multi-reviewer/reviewer-prompts/exemplar-matcher.md`

**Acceptance Criteria:**

Feature: Exemplar-matcher exempts new Gherkin sections
  Scenario: Prompt forbids BLOCKING for Acceptance Scenarios absent in sample
    Given exemplar-matcher.md on disk
    When grep searches for Acceptance Scenarios exemption
    Then output describes must NOT emit BLOCKING for draft sections sample lacks

- [ ] **Step 1: Add section** before `## Output format`:

```markdown
## Pre-Gherkin exemplar exemption (source spec §F.3)

When the assigned sample predates `## Acceptance Scenarios` or plan `**Acceptance Criteria:**`:
- Do **not** emit BLOCKING or IMPORTANT because the draft has these sections and the sample does not.
- `bdd-reviewer` and `tdd-reviewer` are authoritative for Gherkin/TDD requirements on post-implementation drafts.
```

- [ ] **Step 2: Structure self-check**

```bash
grep "Pre-Gherkin" skills/multi-reviewer/reviewer-prompts/exemplar-matcher.md
```

Expected: section header found.

- [ ] **Step 3: Commit**

```bash
git add skills/multi-reviewer/reviewer-prompts/exemplar-matcher.md
git commit -m "$(cat <<'EOF'
feat(multi-reviewer): exemplar-matcher pre-Gherkin exemption

EOF
)"
```

---

### Task 14: Update using-superpowers reviewer count text

**Files:**
- Modify: `skills/using-superpowers/SKILL.md`

**Acceptance Criteria:**

Feature: TDD/BDD reviewers extend multi-reviewer for spec drafts
  Scenario: Bootstrap text reflects six fixed reviewers
    Given using-superpowers SKILL.md on disk after edit
    When grep searches multi-reviewer reviewer count prose
    Then text describes six fixed reviewers not four

- [ ] **Step 1: Find and replace** stale `4 reviewers` / `5–6` with `6 fixed reviewers (plus 0–2 exemplar-matchers)` in multi-reviewer context.

- [ ] **Step 2: Structure self-check** — `rg "4 reviewers" skills/using-superpowers/SKILL.md` expects zero matches in dispatch context.

- [ ] **Step 3: Commit** (same as before).

---

## Chunk 4: End-to-End Validation

### Task 10: Structure self-check — full file inventory

**Files:**
- (read-only verification across repo)

**Acceptance Criteria:**

Feature: All spec File Inventory paths exist
  Scenario: Grep confirms dispatch list complete
    Given implementation commits applied
    When grep searches multi-reviewer SKILL for six fixed reviewers
    Then all six role names appear in section 1

- [ ] **Step 1: Run inventory check**

```bash
for f in \
  skills/multi-reviewer/reviewer-prompts/bdd-reviewer.md \
  skills/multi-reviewer/reviewer-prompts/tdd-reviewer.md \
  skills/multi-reviewer/finding-schema.md \
  skills/multi-reviewer/SKILL.md \
  skills/multi-reviewer/convergence-rules.md \
  skills/multi-reviewer/arbiter-prompt.md \
  skills/multi-reviewer/reviewer-prompts/exemplar-matcher.md \
  skills/brainstorming/SKILL.md \
  skills/writing-plans/SKILL.md; do
  test -f "$f" || echo "MISSING: $f"
done
```

Expected: no MISSING lines.

- [ ] **Step 2: Run dispatch grep**

```bash
grep -E "architect.*red-team.*edge-cases.*yagni.*bdd-reviewer.*tdd-reviewer" skills/multi-reviewer/SKILL.md || \
grep -A2 "Always include" skills/multi-reviewer/SKILL.md
```

Expected: six roles listed in §1.

- [ ] **Step 3: Run stale-reference grep (expanded scope)**

```bash
rg "4 reviewers only|4 fixed reviewers|5–6" skills/brainstorming skills/writing-plans skills/multi-reviewer skills/using-superpowers skills/resume-brainstorming/templates skills/resume-planning/templates samples/README.md || true
```

Expected: zero matches after Task 14 fix; record any hit as failure.

- [ ] **Step 4: Record results** — paste output in PR description.

---

### Task 11: Agent behavior test — spec-draft and plan-draft dispatch

**Acceptance Criteria:**

Feature: Malformed reviewer output triggers re-dispatch
  Scenario: Partial round excludes failed reviewer from STOP_CONVERGED
    Given a fixed reviewer returns malformed YAML twice in Round 1
    When arbiter processes successful receipts only
    Then convergence_status is not STOP_CONVERGED unless user accepts partial round

Feature: Six-reviewer spec-draft dispatch
  Scenario: noop-test-hook brainstorming records six reviewers
    Given brainstorming completes on topic noop-test-hook per source spec Testing Strategy item 2
    When decision-log Round 1 is written
    Then dispatched list includes bdd-reviewer and tdd-reviewer

- [ ] **Step 1: Behavior-test (spec Testing Strategy item 2)** — run brainstorming on topic `noop-test-hook` (minimal session); confirm decision-log Round 1 lists six fixed reviewers. Follow `skills/writing-skills/testing-skills-with-subagents.md`.

- [ ] **Step 2: Behavior-test (plan-draft)** — invoke multi-reviewer Round 1 on this plan with `document_type: plan-draft`; confirm tdd-reviewer payload includes Testing Strategy section reference.

- [ ] **Step 3: Behavior-test (legacy source spec)** — plan-draft fixture whose source spec lacks `## Testing Strategy`; assert `testing_strategy_absent: true` and tdd-reviewer BLOCKING per §C.1.

- [ ] **Step 4: Partial-round + invalid document_type** — malformed YAML twice → `excluded_roles`; invalid `document_type` → re-dispatch once; all reviewers fail → round failed, no arbiter.

- [ ] **Step 5: Teardown** — delete `/tmp` fixtures.

- [ ] **Step 6: Record pass/fail** in PR description.

---

### Task 12: bdd-reviewer prompt isolation test

**Acceptance Criteria:**

Feature: Spec draft fails bdd-reviewer without Acceptance Scenarios
  Scenario: Isolation dispatch on incomplete fixture
    Given a spec fixture missing ## Acceptance Scenarios
    When bdd-reviewer alone reviews with document_type spec-draft
    Then output is BLOCKING YAML per finding-schema

- [ ] **Step 1: Create `/tmp/fixture-no-acceptance-spec.md`** — Problem + Goals only, no Acceptance Scenarios.

- [ ] **Step 2: Dispatch bdd-reviewer subagent** — follow `skills/writing-skills/testing-skills-with-subagents.md`; expect BLOCKING finding.

- [ ] **Step 3: Teardown and record pass/fail** in PR description.

---

### Task 13: tdd-reviewer prompt isolation test

**Acceptance Criteria:**

Feature: Code task missing run-to-fail step
  Scenario: Isolation dispatch on plan task without RED step
    Given a plan task block with .ts Files and no failing-test step
    When tdd-reviewer alone reviews with document_type plan-draft
    Then output is BLOCKING YAML per finding-schema

- [ ] **Step 1: Create `/tmp/fixture-bad-plan-task.md`** — single Task with `.ts` file, implementation step only.

- [ ] **Step 2: Dispatch tdd-reviewer** — follow `skills/writing-skills/testing-skills-with-subagents.md`; expect BLOCKING for missing run-to-fail.

- [ ] **Step 3: Teardown and record pass/fail** in PR description.

---

**Phase 3 deferral (spec optional):** Do not add `samples/specs/INDEX.md` Gherkin note in this PR unless user explicitly requests via `managing-samples`. Record deferral in PR description.

## Spec Coverage Matrix

| Spec requirement | Plan task |
|------------------|-----------|
| §A.1 six fixed reviewers | Task 6, 7 |
| §A.2 document_type + payload | Task 6 |
| §B bdd-reviewer prompt | Task 3 |
| §C tdd-reviewer prompt | Task 4 |
| §D spec Acceptance Scenarios template | Task 1 |
| §E plan Acceptance Criteria template | Task 2 |
| §F controller dispatch | Task 6 |
| §F.3 exemplar exemption | Task 9 |
| §G error handling / receipt SM | Task 6, 7, 8 |
| finding-schema roles | Task 5 |
| arbiter precedence | Task 8 |
| Phase 1 before Phase 2 atomic release | File Map + chunk order |
| §Testing Strategy items 1–4 | Task 10, 11, 12, 13 |
| using-superpowers bootstrap | Task 14 (before Task 10 stale grep) |
