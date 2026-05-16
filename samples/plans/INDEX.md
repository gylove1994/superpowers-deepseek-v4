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

- file: 2026-01-22-document-review-system.md
  topic: Adding spec and plan reviewer prompts plus review loops to brainstorming and writing-plans skills
  domain: skill workflow integration
  scale: small
  characteristics:
    - 3 chunks, 5 small tasks
    - reviewer prompt templates inlined as markdown blobs
    - per-step verification command with expected output
    - per-task commit
  problem_summary: How to add reviewer subagent dispatch and review loops to two existing skills, task-by-task, with verification steps after every change
  why_exemplar: Tight task scoping (one file or one feature each), expected-output annotation on every verification step, and disciplined per-task commit messages

- file: 2026-02-19-visual-brainstorming-refactor.md
  topic: TDD-rhythm refactor plan for the visual brainstorming server, template, client, tests, and skill
  domain: server-and-client refactor
  scale: medium
  characteristics:
    - File Map table prefacing tasks
    - failing-test-first rhythm before each implementation step
    - dedicated cleanup task with grep verification of stale references
    - obsolete-file deletion as its own numbered task
    - final smoke-test task with explicit start/stop server commands
  problem_summary: How to refactor a multi-component browser companion file-by-file with TDD and explicit cleanup of stale references to deleted code
  why_exemplar: File Map at the top, write-failing-test-then-implement rhythm, a regex-grep cleanup task that catches stale references, and a final smoke-test task tying everything end-to-end

- file: 2026-03-11-zero-dep-brainstorm-server.md
  topic: Layer-ordered plan to swap a vendored brainstorm server for a single zero-dependency file
  domain: dependency reduction
  scale: medium
  characteristics:
    - File Map listing create / modify / delete / no-change for each file
    - chunks ordered by architectural layer (protocol then app then swap)
    - inline code skeletons in every implementation step
    - explicit `git rm` for vendored deletions
    - manual smoke test as a final task with expected outputs
  problem_summary: How to incrementally replace a multi-dependency Node server with a single zero-dep file without breaking the existing test surface
  why_exemplar: Layer-ordered chunking (protocol then app then swap), per-step code skeletons, and a manual smoke test that walks each expected behavior with concrete commands

- file: 2026-03-23-codex-app-compatibility.md
  topic: Surgical insertion of read-only environment detection across worktree and finishing skills
  domain: skill modification
  scale: medium
  characteristics:
    - line-numbered insertion points for each edit
    - before/after markdown blocks per insertion
    - read-and-verify step after every insertion
    - ticket-tagged commit messages
    - standalone bash test exercising detection logic on real worktrees
  problem_summary: How to add an environment-detection block to five skill files via line-pinned surgical edits and prove it works with an automated bash test
  why_exemplar: Line-pinned edits with full before/after blocks, ticket-prefixed commit messages, and a standalone bash test that creates real worktrees and asserts the detection result

- file: 2026-04-06-worktree-rototill.md
  topic: TDD-gated full-rewrite plan for the worktree and finishing skills with native-tool preference
  domain: skill rewrite
  scale: large
  characteristics:
    - GATE task with explicit stop-after-2-REFACTOR-iterations rule
    - RED / GREEN / PRESSURE phases for an agent-behavior test
    - full SKILL.md replacements rather than line edits
    - bundled integration-line updates across three sibling skills
    - end-to-end verification task that re-reads both rewritten skills
  problem_summary: How to validate a high-risk design assumption against real agent behavior before any skill files are modified, then perform full-file rewrites with end-to-end verification
  why_exemplar: An explicit GATE task with stop conditions, RED/GREEN/PRESSURE behavior-test phases, and full SKILL.md content embedded in the plan body for reviewability
