# Spec & Plan TDD/BDD Independent Review Design

**Date:** 2026-05-21
**Status:** Draft
**Fork:** `superpowers-deepseek-v4`

## Problem

The fork's `multi-reviewer` subsystem dispatches four fixed reviewers (architect, red-team, edge-cases, yagni-gatekeeper) plus 0–2 exemplar-matchers when brainstorming or writing-plans produces a draft. These reviewers cover architecture, adversarial scenarios, edge paths, and scope control — but **none independently audit testability or behavior specification quality**.

Concrete gaps observed in real spec/plan drafts:

1. **Specs lack verifiable acceptance criteria** — Goals and Design sections describe intent in prose, but downstream `writing-plans` cannot trace tasks to observable pass/fail outcomes.
2. **Plans omit TDD rhythm on code tasks** — Tasks jump to implementation without RED→GREEN→REFACTOR steps, or conflate "commit" with an acceptance criterion.
3. **Skill/prompt tasks have no verification substitute** — When unit tests do not apply, plans either skip verification entirely or invent fake test steps.
4. **Single-context blind spot on test design** — The drafting agent and existing reviewers share no dedicated lens for "can this be tested?" or "what behavior must hold?"

The fork already requires TDD rhythm in `writing-plans` prose, but enforcement is implicit — not an isolated reviewer context with explicit boundaries and BLOCKING findings.

## Goals

1. Add **`bdd-reviewer`** and **`tdd-reviewer`** as two new fixed parallel reviewers inside `multi-reviewer`, raising the fixed reviewer count from 4 to 6 (plus 0–2 exemplar-matchers unchanged).
2. **`bdd-reviewer`** enforces strict **Gherkin** (Given/When/Then) acceptance scenarios on spec drafts and per-task acceptance criteria on plan drafts.
3. **`tdd-reviewer`** enforces **RED→GREEN→REFACTOR** on code tasks and **verifiable pass criteria** (structure self-check or behavior-test scenario) on skill/prompt/document tasks.
4. Update **spec and plan document structure** so drafts are authored with the required sections before review, reducing round-trip revision cost.
5. Update **`brainstorming`** and **`writing-plans`** SKILLs to require the new sections when writing initial drafts.
6. Keep **convergence rules unchanged** (50% degradation threshold, 3-round cap, 3 NITs/reviewer). Six fixed reviewers increase round-1 raw finding volume; `prev_total` is not normalized by receipt count — authors should expect similar or slightly higher STOP_DEGENERATE frequency versus the four-reviewer baseline.
7. Scope limited to **spec + plan stages** only. Execute phase skills remain unchanged.

## Non-Goals

- **Execute-phase review** — No changes to `subagent-driven-development`, `executing-plans`, or per-task implementer review loops.
- **`test-driven-development` SKILL rewrite** — Reference it from `tdd-reviewer` prompts; do not modify the skill file in this change set.
- **Automated test runners or CI** — This is a prompt-template / workflow change only; zero new dependencies.
- **Gherkin parser or linter tooling** — Format compliance is reviewer-enforced, not machine-validated.
- **Convergence rule retuning** — Degradation threshold and round cap stay at 50% and 3 unless a future spec addresses empirical STOP_DEGENERATE frequency.
- **Retroactive migration of existing Done specs/plans** — New requirements apply to drafts written after implementation; samples library updates are optional follow-up.

## Design Principles

### Narrow reviewer mandates with explicit boundaries

Each new reviewer has a single lens and a "do NOT look at" list, matching existing reviewers. Overlap with architect (modularity) or edge-cases (failure paths) is expected; arbiter dedup resolves it.

### Template anchors before reviewer enforcement

Strict Gherkin without structural anchors causes authors to discover format requirements only at review time. Spec and plan templates gain mandatory sections so `bdd-reviewer` has stable `location` references.

### Layered TDD rules by task type

Code tasks: mandatory RED→GREEN→REFACTOR steps. Non-code tasks (SKILL.md, prompt templates, pure documentation): allow `structure self-check` or `behavior-test scenario` per existing `writing-plans` convention, but **must** declare observable pass criteria — never skip verification.

### English prompts, any-language draft content

All new reviewer prompt files and SKILL edits use English. Gherkin scenarios in drafts may use the user's language for step text; keywords (`Feature`, `Scenario`, `Given`, `When`, `Then`, `And`) remain English per Gherkin convention.

### No mid-loop commits

All multi-reviewer state updates remain in the decision-log / plan-progress file. Terminal commit only when brainstorming or writing-plans reaches Done.

## Acceptance Scenarios

Feature: TDD/BDD reviewers extend multi-reviewer for spec drafts
  Scenario: Spec draft passes bdd-reviewer with complete Gherkin
    Given a spec draft with a "## Acceptance Scenarios" section placed after Design Principles
    And every numbered Goal in "## Goals" has at least one Gherkin scenario demonstrating it
    When multi-reviewer dispatches bdd-reviewer with document_type spec-draft
    Then bdd-reviewer returns NO_BLOCKING_ISSUES true

  Scenario: Spec draft fails bdd-reviewer without Acceptance Scenarios
    Given a spec draft missing "## Acceptance Scenarios"
    When multi-reviewer dispatches bdd-reviewer with document_type spec-draft
    Then bdd-reviewer emits a BLOCKING finding with location "## Acceptance Scenarios"

Feature: Spec and plan templates require new sections before review
  Scenario: Brainstorming spec includes Acceptance Scenarios on first draft
    Given brainstorming Phase B Step 6 writes an initial spec draft
    When the draft is saved to docs/superpowers/specs/
    Then the draft contains a "## Acceptance Scenarios" section with at least one Feature block
    And the brainstorming SKILL Step 6 section list includes Acceptance Scenarios

  Scenario: Writing-plans task includes Acceptance Criteria
    Given writing-plans Step 4 writes a plan task block
    When the task modifies any file
    Then the task contains "**Acceptance Criteria:**" with at least one Gherkin Scenario
    And the writing-plans SKILL Step 4 documents this requirement

Feature: TDD reviewer enforces RED-GREEN on code plan tasks
  Scenario: Code task missing run-to-fail step
    Given a plan draft with a Task whose Files include a .ts source file
    And the task steps jump directly to implementation without a failing test step
    When multi-reviewer dispatches tdd-reviewer with document_type plan-draft
    Then tdd-reviewer emits a BLOCKING finding for missing run-to-fail confirmation

  Scenario: Skill-only task uses behavior-test verification
    Given a plan task that only modifies skills/multi-reviewer/SKILL.md
    And the task includes a behavior-test scenario step with explicit pass criteria
    When multi-reviewer dispatches tdd-reviewer with document_type plan-draft
    Then tdd-reviewer returns NO_BLOCKING_ISSUES true for TDD rhythm

Feature: Non-code task without verification fails tdd-reviewer
  Scenario: SKILL edit task with no verification step
    Given a plan task that modifies a SKILL.md file
    And the task has no structure self-check or behavior-test step
    When multi-reviewer dispatches tdd-reviewer with document_type plan-draft
    Then tdd-reviewer emits a BLOCKING finding for missing verifiable pass criteria

Feature: Exemplar samples without Gherkin do not override bdd-reviewer
  Scenario: Matched exemplar predates Acceptance Scenarios requirement
    Given an exemplar sample in samples/specs/ that lacks "## Acceptance Scenarios"
    And a new spec draft includes "## Acceptance Scenarios" per this spec
    When exemplar-matcher compares the draft to the assigned sample
    Then exemplar-matcher does not emit BLOCKING for missing Acceptance Scenarios in the draft
    And bdd-reviewer remains authoritative for Gherkin completeness

Feature: Malformed reviewer output triggers re-dispatch
  Scenario: Reviewer returns invalid YAML once
    Given a reviewer subagent returns output missing required finding fields
    When the multi-reviewer controller validates the receipt
    Then the controller re-dispatches the same reviewer once with a format reminder
    And the decision-log receipt status shows a retry notation

  Scenario: Reviewer fails twice in the same round
    Given a reviewer returns malformed output on initial dispatch and on re-dispatch
    When the round would otherwise complete
    Then the controller records the failure in the decision-log
    And surfaces the failure to the user during finalization or user-arbitration

Feature: Execute phase remains out of scope (Goal 7)
  Scenario: Implementation proceeds without bdd/tdd re-dispatch
    Given a Done plan produced under this spec's writing-plans flow
    When subagent-driven-development or executing-plans runs implementation tasks
    Then multi-reviewer is not invoked
    And bdd-reviewer and tdd-reviewer are not dispatched during execute phase
    And subagent-driven-development and executing-plans SKILL files require no content changes from this spec

Feature: Malformed Gherkin inside Acceptance Scenarios section
  Scenario: Spec draft has section but broken Gherkin structure
    Given a spec draft with "## Acceptance Scenarios" present
    And a scenario block missing When or Then keywords
    When multi-reviewer dispatches bdd-reviewer with document_type spec-draft
    Then bdd-reviewer emits a BLOCKING finding at location "## Acceptance Scenarios" for malformed Gherkin structure

Feature: Convergence rules unchanged with six fixed reviewers
  Scenario: Round completes with zero BLOCKING and IMPORTANT after revision
    Given a spec draft revised to address all bdd-reviewer and tdd-reviewer BLOCKING findings
    When arbiter processes round N reviewer outputs
    Then arbiter convergence_status is STOP_CONVERGED
    And arbiter degradation_check is PASSED or N/A per decision-log Round N metadata
    And convergence-rules.md still specifies 50% degradation threshold and round cap of 3

## Design

### Updated Workflow

```
brainstorming Phase B → spec draft (with Acceptance Scenarios)
    → multi-reviewer loop (6 fixed + 0–2 exemplar-matchers + arbiter)
    → spec Done → writing-plans → plan draft (per-task Acceptance Criteria)
    → multi-reviewer loop (same reviewer set, document_type plan-draft)
    → plan Done → subagent-driven-development / executing-plans (no bdd/tdd review)
```

**Multi-reviewer loop (spec or plan):**
1. Controller writes Round N to decision-log / plan-progress
2. Parallel dispatch all reviewers (isolated subagent contexts)
3. Validate receipts; re-dispatch malformed once; mark `✗ failed` on second failure
4. Arbiter dedupes, filters, decides CONTINUE | STOP_CONVERGED | STOP_DEGENERATE | STOP_LIMIT
5. If CONTINUE: main flow agent revises draft; goto 1 with round + 1
6. If STOP_* with unresolved: user-arbitration handoff

### A. Multi-reviewer dispatch extension

#### A.1 Updated fixed reviewer set

| # | Reviewer | Role |
|---|----------|------|
| 1 | architect | unchanged |
| 2 | red-team | unchanged |
| 3 | edge-cases | unchanged |
| 4 | yagni-gatekeeper | unchanged |
| 5 | **bdd-reviewer** | **new** |
| 6 | **tdd-reviewer** | **new** |
| 7–8 | exemplar-matcher (0–2) | unchanged, one per matched sample |

Total parallel reviewers per round: **6, 7, or 8** (was 4, 5, or 6).

#### A.2 Document-type prompt variants

Both new reviewers receive a `document_type` parameter at dispatch time:

| `document_type` | Set by | Draft being reviewed |
|-----------------|--------|----------------------|
| `spec-draft` | `brainstorming` Phase B | `docs/superpowers/specs/*-design.md` |
| `plan-draft` | `writing-plans` | `docs/superpowers/plans/*.md` |

Each reviewer has **one prompt file** with two clearly labeled checklists (`## When document_type is spec-draft` / `## When document_type is plan-draft`). The controller injects `document_type` at the top of the dispatch message.

#### A.2.1 Dispatch payload (per role)

| Reviewer | Required inputs |
|----------|-----------------|
| All reviewers | `draft` (full text), `reviewer_role`, `document_type` (`spec-draft` \| `plan-draft`) — controller validates enum; invalid value → receipt `✗ failed`, §G row |
| plan-draft **bdd-reviewer** | `source_spec_path`, **full text** of source spec (for legacy traceability when section exists) |
| plan-draft **tdd-reviewer** | `source_spec_path`, **full text** of source spec `## Testing Strategy` section only (read-only alignment check) |
| exemplar-matcher | `assigned_sample` filename + full sample content |

#### A.3 Files to change in multi-reviewer

| File | Change |
|------|--------|
| `skills/multi-reviewer/SKILL.md` | Update dispatch list, reviewer count, document_type + payload table, **receipt state machine in steps 3–5** (validate → re-dispatch once → `✗ failed` → exclude from arbiter) |
| `skills/multi-reviewer/convergence-rules.md` | Update pseudocode `fixed_reviewers` set; **STOP_CONVERGED guard when fixed reviewer ✗ failed**; comment "6–8 parallel reviewers" |
| `skills/multi-reviewer/finding-schema.md` | Add `bdd-reviewer` and `tdd-reviewer` to `reviewer_role` enum |
| `skills/multi-reviewer/reviewer-prompts/bdd-reviewer.md` | **new** |
| `skills/multi-reviewer/reviewer-prompts/tdd-reviewer.md` | **new** |
| `skills/multi-reviewer/arbiter-prompt.md` | Step 3 bdd/tdd precedence; **forbid STOP_CONVERGED when excluded fixed reviewers unless user-arbitration accepts partial round**; mixed-task template reference §C.5 |

### B. bdd-reviewer

**Purpose:** Verify that every user-visible behavior is expressed as testable Gherkin scenarios with explicit Given/When/Then structure.

**Location:** `skills/multi-reviewer/reviewer-prompts/bdd-reviewer.md`

**Output format:** YAML findings per `finding-schema.md`; `NO_BLOCKING_ISSUES: true` when clean.

**Review loop:** Findings → main flow agent revises draft → next multi-reviewer round until arbiter `STOP_CONVERGED`.

**Dispatch mechanism:** Multi-reviewer controller parallel Task batch with `document_type` preamble (§F.1).

#### B.1 spec-draft checklist

| Category | What to Look For | Severity |
|----------|------------------|----------|
| Goals non-empty | `## Goals` contains ≥1 numbered item | BLOCKING if empty |
| Section presence | `## Acceptance Scenarios` section exists | BLOCKING if missing |
| Section placement | Section appears after `## Design Principles` and before `## Design` | BLOCKING if elsewhere |
| Scenario non-empty | Section contains ≥1 `Scenario:` block (not header-only) | BLOCKING if empty |
| Gherkin structure | Each scenario uses `Feature`/`Scenario`/`Given`/`When`/`Then` (`And` allowed) | BLOCKING if malformed |
| Goal coverage | Every Goal has ≥1 scenario demonstrating it | BLOCKING if uncovered |
| Observable outcomes | `Then` clauses describe observable state, not implementation steps | IMPORTANT if vague |
| Negative paths | At least one scenario covers a failure or rejection path when Goals imply error handling | IMPORTANT if absent |

#### B.2 plan-draft checklist

| Category | What to Look For | Severity |
|----------|------------------|----------|
| Per-task criteria | Every `### Task N:` block has `**Acceptance Criteria:**` with ≥1 Gherkin scenario | BLOCKING if missing |
| Spec traceability | Each task's scenarios map to a spec `## Acceptance Scenarios` entry when source spec **has** that section | IMPORTANT if orphan when section exists |
| Legacy spec | Source spec lacks `## Acceptance Scenarios` (pre-change Done spec) | Skip traceability IMPORTANT; per-task Gherkin still BLOCKING |
| Outcome vs process | `Then` describes verifiable outcome, not "commit" or "file edited" alone | BLOCKING if process-only |
| Non-task sections | Plan header Goal/Architecture unchanged — reviewer does not require Gherkin there | N/A |

#### B.3 bdd-reviewer boundaries (do NOT look at)

- TDD step ordering (tdd-reviewer)
- Architecture modularity (architect)
- Scope creep additions (yagni-gatekeeper)
- Internal test framework choice (tdd-reviewer on spec `Testing Strategy`)

#### B.4 Minimum Gherkin example (normative for drafts)

```gherkin
Feature: Multi-reviewer dispatches bdd-reviewer
  Scenario: Spec draft missing Acceptance Scenarios section
    Given a spec draft produced by brainstorming Phase B
    When the multi-reviewer subsystem dispatches bdd-reviewer with document_type spec-draft
    Then bdd-reviewer emits a BLOCKING finding for missing "## Acceptance Scenarios"
```

### C. tdd-reviewer

**Purpose:** Verify that testing approach (spec) and task steps (plan) follow test-first discipline appropriate to the task type.

**Location:** `skills/multi-reviewer/reviewer-prompts/tdd-reviewer.md`

**Output format:** YAML findings per `finding-schema.md`; `NO_BLOCKING_ISSUES: true` when clean.

**Review loop:** Same as §B bdd-reviewer.

**Dispatch mechanism:** Same as §B; plan-draft also receives `source_spec_path` + full `## Testing Strategy` text for alignment checks (§A.2.1).

References (read-only, cited in prompt): `skills/test-driven-development/SKILL.md`, `skills/writing-plans/SKILL.md`, `skills/writing-skills/testing-skills-with-subagents.md`.

#### C.1 spec-draft checklist

| Category | What to Look For | Severity |
|----------|------------------|----------|
| Testing Strategy section | `## Testing Strategy` exists and is non-empty | BLOCKING if missing |
| Test-first principle | Strategy states tests/specs precede implementation for code changes | IMPORTANT if absent |
| Verifiable commands | Strategy names concrete verification commands or agent-behavior test protocol | BLOCKING if only "write tests" |
| Non-code path | Strategy names structure self-check or subagent behavior-test protocol for SKILL/prompt changes | IMPORTANT if spec touches skills and omits this |
| RED/GREEN language | Uses RED→GREEN→REFACTOR or equivalent explicit cycle for code | NIT |

#### C.2 plan-draft checklist — code tasks

| Category | What to Look For | Severity |
|----------|------------------|----------|
| Code task trigger | Task **Files** includes a source-code extension (e.g., `.ts`, `.js`, `.py`) | Determines §C.2 vs §C.3 |
| Spec alignment | Task verification method does not contradict source spec `## Testing Strategy` | BLOCKING if contradicts |
| RED step | Failing test written before implementation step | BLOCKING if missing |
| Run-to-fail | Explicit command/step to run test and confirm failure | BLOCKING if missing |
| GREEN step | Minimal implementation step | BLOCKING if missing |
| Run-to-pass | Explicit command/step to confirm pass | BLOCKING if missing |
| Order | RED before GREEN in step numbering | BLOCKING if reversed |

#### C.3 plan-draft checklist — non-code tasks (SKILL.md, prompts, docs)

| Category | What to Look For | Severity |
|----------|------------------|----------|
| Spec alignment | Task verification does not contradict source spec `## Testing Strategy` (e.g., no invented `npm test` when spec forbids it) | BLOCKING if contradicts |
| Verification present | Task includes structure self-check OR behavior-test scenario step | BLOCKING if neither |
| Pass criteria | Step states observable pass condition (not "looks good") | BLOCKING if vague |
| No fake unit tests | Task does not invent `npm test` / pytest for markdown-only edits | IMPORTANT if present |
| TDD skill reference | Behavior-test tasks cite `testing-skills-with-subagents` pattern | NIT |

#### C.4 tdd-reviewer boundaries (do NOT look at)

- Gherkin formatting of acceptance criteria (bdd-reviewer)
- Whether scenarios cover all Goals (bdd-reviewer)
- Architecture (architect)

#### C.5 Mixed code + skill tasks (normative step order)

When a `### Task N:` **Files** list includes both code (e.g., `.ts`) and SKILL/prompt paths:

1. **Code steps first** — full RED → run-to-fail → GREEN → run-to-pass sequence for code files
2. **Skill/prompt steps second** — structure self-check or behavior-test scenario with explicit pass criteria
3. **Single commit step last**

tdd-reviewer applies §C.2 to steps in group 1 and §C.3 to steps in group 2. No BLOCKING for "verification before code" across groups — only within each group.

### D. Spec document template change

Add mandatory section to spec structure (brainstorming Step 6 and spec samples going forward):

```markdown
## Acceptance Scenarios

Feature: <feature name>
  Scenario: <happy path>
    Given <precondition>
    When <action>
    Then <observable outcome>

  Scenario: <failure or edge path>
    Given <precondition>
    When <action>
    Then <observable outcome>
```

Placement: **after `## Design Principles`, before `## Design`** — mandatory and normative. Reviewers emit BLOCKING if the section is absent or placed elsewhere.

Update `brainstorming` SKILL Step 6 spec section list to include `Acceptance Scenarios`.

### E. Plan document template change

Add to each `### Task N:` block in `writing-plans` Step 4:

```markdown
**Acceptance Criteria:**

Feature: <task-scoped feature>
  Scenario: <verifiable outcome>
    Given <precondition>
    When <action>
    Then <observable outcome>
```

For code tasks, acceptance criteria describe **outcome**; TDD steps describe **process**. Both are required and complementary.

**Full normative task example (skill-only task):**

```markdown
- [ ] ### Task 2: Add bdd-reviewer dispatch to multi-reviewer SKILL

**Files:**
- Modify: `skills/multi-reviewer/SKILL.md`

**Acceptance Criteria:**

Feature: bdd-reviewer dispatch
  Scenario: SKILL lists bdd-reviewer in fixed set
    Given multi-reviewer SKILL.md on disk
    When grep searches for bdd-reviewer in dispatch list
    Then bdd-reviewer appears alongside architect and tdd-reviewer

- [ ] **Step 1: Structure self-check** — confirm §1 lists exactly six fixed reviewers including bdd-reviewer and tdd-reviewer
- [ ] **Step 2: Behavior-test** — dispatch multi-reviewer on fixture spec missing Acceptance Scenarios; expect bdd-reviewer BLOCKING in Round 1 decision-log
- [ ] **Step 3: Edit SKILL.md** — add bdd-reviewer to §1 dispatch list per spec §A.3
- [ ] **Step 4: Re-run behavior-test** — expect NO_BLOCKING_ISSUES from bdd-reviewer on compliant fixture
- [ ] **Step 5: Commit** — `git add skills/multi-reviewer/SKILL.md && git commit -m "feat(multi-reviewer): dispatch bdd-reviewer"`
```

**Code task note:** When **Files** includes `.ts` (or other code extensions), use full §C.2 RED→run-to-fail→GREEN→run-to-pass steps with a **real** test command that exists in the repo — never invent scripts (see §C.3 fake unit tests rule).

Update `writing-plans` SKILL Step 4 task structure documentation.

### F. Controller dispatch changes

#### F.1 brainstorming Phase B (multi-reviewer Step 3)

When dispatching reviewers, the controller additionally:

1. Sets `document_type: spec-draft` in each new reviewer's prompt preamble.
2. Includes `bdd-reviewer` and `tdd-reviewer` in the parallel batch.
3. Updates decision-log Round N dispatched list to show 6 fixed + exemplar-matchers.

#### F.2 writing-plans (multi-reviewer Step 3)

Same as F.1 with `document_type: plan-draft`. Pass `source_spec_path` + full source spec text to **bdd-reviewer**; pass `source_spec_path` + source spec `## Testing Strategy` full text to **tdd-reviewer**.

#### F.3 Exemplar-matcher interaction with new sections

When an assigned exemplar sample predates this spec and lacks `## Acceptance Scenarios` or per-task `**Acceptance Criteria:**`:

- **exemplar-matcher** must NOT emit BLOCKING or IMPORTANT for the draft having sections the sample lacks.
- **bdd-reviewer** and **tdd-reviewer** are authoritative for Gherkin and TDD requirements on all post-implementation drafts.
- **exemplar-matcher** may NIT-note that the sample could be updated separately (user-driven via `managing-samples`).

### G. Error handling

| Case | Handling |
|------|----------|
| Invalid `document_type` | Receipt `✗ failed`; re-dispatch once with valid enum; else exclude per malformed path |
| Reviewer returns malformed YAML, empty output, non-YAML, or crash | Re-dispatch once with format reminder; validate `NO_BLOCKING_ISSUES` when findings empty; second failure → receipt `✗ failed`, exclude from arbiter input |
| **All reviewers failed** | Do **not** call arbiter; do **not** set STOP_CONVERGED; mark round failed in decision-log; surface to user for retry or abort |
| Partial round failure | If ≥1 reviewer succeeds, arbiter runs on successful receipts only; failed roles noted for user |
| **Fixed reviewer excluded twice** | Arbiter **must not** emit STOP_CONVERGED; controller forces user-arbitration or fresh round 1 after fix unless user explicitly accepts partial round in decision-log |
| bdd/tdd conflict on same task | Arbiter Step 3 precedence: Gherkin format → bdd-reviewer; step ordering → tdd-reviewer |
| Task is both code and skill edit | Apply §C.5 mixed-task step order |
| Empty Acceptance Scenarios with placeholder | BLOCKING |
| STOP_DEGENERATE with bdd/tdd findings | Standard user-arbitration handoff |
| Reviewer/agent disagreement across rounds | After 3 rounds on same finding ID → user-arbitration Accept/Reject/Defer |

## Risks

| Risk | Status | Mitigation |
|------|--------|------------|
| Increased review latency (6–8 parallel reviewers vs 4–6) | Accepted | No convergence rule change; arbiter dedup; user chose quality over speed in Phase A |
| Exemplar samples without Gherkin mislead drafting agents | Mitigated | §F.3 exempts exemplar-matcher from penalizing new sections; bdd-reviewer enforces Gherkin |
| Strict Gherkin friction on small specs | Accepted | User chose strict Gherkin in Phase A Q4; template anchors reduce round trips |
| tdd-reviewer false BLOCKING on skill-only plans | Mitigated | Layered rules (Phase A Q3): structure self-check / behavior-test allowed for non-code |
| Partial reviewer failure mid-round | Mitigated | §G partial round failure row |

**Residual:** Empirical STOP_DEGENERATE frequency with 6 fixed reviewers is unknown until post-implementation use. `prev_total` is **not** normalized by successful receipt count — decision-log Round N metadata should record `dispatched_count`, `successful_receipt_count`, and `excluded_roles` so humans can interpret degradation. Retuning convergence rules is explicitly deferred to a future spec if needed.

## Implementation Phases

**Release gate:** Phase 1 and Phase 2 ship in the **same release** (atomic). Reviewer dispatch must not activate until brainstorming/writing-plans templates document Acceptance Scenarios / Acceptance Criteria (Design Principle: template anchors before enforcement).

### Phase 1: SKILL and template integration (must land first in commit order)

1. Update `brainstorming` SKILL Step 6 spec section list + Acceptance Scenarios placement rule.
2. Update `writing-plans` SKILL Step 4 task template + full example per §E.
3. Update decision-log / plan-progress templates if they embed structure hints.

### Phase 2: Reviewer prompts and schema (same release, after Phase 1 files in same PR)

1. Create `bdd-reviewer.md` and `tdd-reviewer.md` with spec-draft and plan-draft checklists.
2. Update `finding-schema.md`, `multi-reviewer/SKILL.md`, `convergence-rules.md`, `arbiter-prompt.md`, `exemplar-matcher.md` (§F.3).

### Phase 3: Documentation and samples (optional but recommended)

1. Add INDEX entry note in `samples/specs/INDEX.md` describing Gherkin expectation for new samples.
2. Do **not** rewrite existing sample files in this phase unless a separate user request — avoids scope creep.

### Phase 4: Validation

1. Dry-run multi-reviewer round 1 against this spec draft (meta — done during brainstorming Phase B).
2. After implementation, run acceptance test: produce a minimal spec through brainstorming and confirm bdd/tdd reviewers dispatch and emit structured findings.

## Testing Strategy

### Spec/plan stage (this change set)

This change modifies SKILL.md and prompt templates only — no application code. Verification uses test-first discipline where applicable:

1. **Structure self-check** — Every file in File Inventory exists; grep confirms `bdd-reviewer` and `tdd-reviewer` in dispatch list.
2. **Agent behavior test** — After implementation, run brainstorming on topic `noop-test-hook`; confirm decision-log Round 1 lists all six fixed reviewers (`architect`, `red-team`, `edge-cases`, `yagni-gatekeeper`, `bdd-reviewer`, `tdd-reviewer`).
3. **bdd-reviewer prompt isolation test** — Dispatch bdd-reviewer alone against draft missing `## Acceptance Scenarios`; expect BLOCKING YAML per finding-schema.
4. **tdd-reviewer prompt isolation test** — Dispatch tdd-reviewer alone against plan-draft task missing RED step; expect BLOCKING YAML per finding-schema.

**Test-first principle for code changes:** Any future spec that adds executable verification tooling to this subsystem must follow RED→GREEN→REFACTOR per `test-driven-development` SKILL. This spec itself has no code tasks.

### Code tasks (N/A for this spec)

No runtime code is added. Future specs that add executable tooling would use RED→GREEN per `test-driven-development` SKILL.

## File Inventory

### New files

| Path | Purpose |
|------|---------|
| `skills/multi-reviewer/reviewer-prompts/bdd-reviewer.md` | bdd-reviewer prompt with spec/plan checklists |
| `skills/multi-reviewer/reviewer-prompts/tdd-reviewer.md` | tdd-reviewer prompt with layered task-type rules |

### Modified files

| Path | Change summary |
|------|----------------|
| `skills/multi-reviewer/SKILL.md` | 6 fixed reviewers; document_type dispatch; file refs |
| `skills/multi-reviewer/convergence-rules.md` | fixed_reviewers set; comment update |
| `skills/multi-reviewer/finding-schema.md` | reviewer_role enum |
| `skills/multi-reviewer/arbiter-prompt.md` | Step 3 bdd/tdd precedence; input role list |
| `skills/brainstorming/SKILL.md` | Acceptance Scenarios in spec structure; multi-reviewer note |
| `skills/writing-plans/SKILL.md` | Acceptance Criteria per task; multi-reviewer note |
| `skills/multi-reviewer/reviewer-prompts/exemplar-matcher.md` | §F.3 exemption for pre-Gherkin samples |

### Unchanged files (explicit)

| Path | Reason |
|------|--------|
| `skills/test-driven-development/SKILL.md` | Non-Goal — referenced only |
| `skills/subagent-driven-development/SKILL.md` | Execute phase out of scope |
| `skills/executing-plans/SKILL.md` | Execute phase out of scope |
| `skills/multi-reviewer/reviewer-prompts/architect.md` | No content change |
| `skills/multi-reviewer/reviewer-prompts/red-team.md` | No content change |
| `skills/multi-reviewer/reviewer-prompts/edge-cases.md` | No content change |
| `skills/multi-reviewer/reviewer-prompts/yagni-gatekeeper.md` | No content change |

## Out of Scope

- Execute-phase TDD/BDD review
- Gherkin lint tooling or CI integration
- Retroactive rewrite of `samples/specs/*` or `samples/plans/*`
- Convergence threshold tuning
- Upstream obra/superpowers sync
