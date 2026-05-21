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

Always invoke `superpowers-deepseek-v4:resume-brainstorming` first. It either:
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
- If 0 samples are selected (no good matches), record this; the multi-reviewer subsystem will run with 6 fixed reviewers (plus 0–2 exemplar-matchers).

Load the chosen samples' full content into your context.

## Step 6: Write the initial spec draft

Write `docs/superpowers/specs/<today>-<topic-slug>-design.md` from scratch. Use the Alignment Summary as your input. Use the matched samples as structural references.

The spec should contain, in order: Problem, Goals, Non-Goals, Design Principles, **Acceptance Scenarios** (Gherkin Feature/Scenario/Given/When/Then blocks — mandatory, placed here), Design (with subsections per major component), Implementation Phases, Testing Strategy, File Inventory, Out of Scope. Adjust subsection depth to suit the topic; do not omit Acceptance Scenarios.

After writing, update the decision log's Phase B Spec Writing Status: `[✓] Initial draft complete (time: <now>)`. Update `Current Phase: review_round_1`.

## Step 7: Multi-reviewer loop

Invoke `superpowers-deepseek-v4:multi-reviewer`. Pass:
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

If the user agrees, invoke `superpowers-deepseek-v4:writing-plans`. Do not invoke any other implementation skill.

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

- `superpowers-deepseek-v4:resume-brainstorming` (mandatory first step)
- `superpowers-deepseek-v4:multi-reviewer` (Phase B review loop)
- `samples/specs/INDEX.md` and any sample file selected
- `docs/superpowers/brainstorms/<filename>-brainstorm.md` (the decision log)
- `docs/superpowers/specs/<filename>-design.md` (the produced spec)
- `./visual-companion.md` (optional, when visual aids will help)
