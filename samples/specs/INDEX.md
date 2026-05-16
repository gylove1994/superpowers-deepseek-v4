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

- file: 2026-01-22-document-review-system-design.md
  topic: Iterative reviewer subagent loops between brainstorming and writing-plans stages
  domain: skill workflow design
  scale: medium
  characteristics:
    - subagent-dispatched document reviewers
    - chunk-by-chunk plan review
    - iterative loop with explicit termination handling
    - tabular what-to-check criteria
  problem_summary: How to insert reviewer subagent loops after spec and plan documents are written so they are verified before downstream work begins
  why_exemplar: Compact tables defining what to check per category, plus an Error Handling section that names disagreement, malformed-output, and iteration-limit cases explicitly

- file: 2026-02-19-visual-brainstorming-refactor-design.md
  topic: Non-blocking browser-display / terminal-conversation refactor of the visual brainstorming companion
  domain: tool architecture
  scale: medium
  characteristics:
    - turn-based platform model
    - file-based event stream (.events JSONL)
    - browser-as-display, terminal-as-conversation separation
    - per-file before/after change lists
  problem_summary: How to keep the TUI responsive during visual brainstorming by replacing TaskOutput-blocking with a per-screen event file the agent reads on its next turn
  why_exemplar: Problem rooted in a concrete platform constraint, followed by per-file remove/keep/add lists, and explicit What-This-Enables / What-This-Drops trade-off sections

- file: 2026-03-11-zero-dep-brainstorm-server-design.md
  topic: Single-file zero-dependency replacement for the vendored brainstorm server
  domain: dependency reduction
  scale: medium
  characteristics:
    - RFC 6455 WebSocket subset implementation
    - deliberately-skipped-features list with rationale
    - dual-mode module (run directly vs require for tests)
    - environment-variable configuration table
  problem_summary: How to eliminate 700+ vendored third-party files in the brainstorm server while preserving its external contract and test surface
  why_exemplar: Tight architecture overview that names every primitive used, plus a Before/After table and a What-Stays-the-Same list that pin the contract

- file: 2026-03-23-codex-app-compatibility-design.md
  topic: Adapting worktree and finishing skills for the Codex App sandboxed detached-HEAD environment
  domain: harness compatibility
  scale: medium
  characteristics:
    - empirical-findings table from sandbox testing
    - read-only git environment detection (git-dir vs git-common-dir)
    - decision matrix mapping env state to action
    - sandbox-fallback for late-detected permission errors
    - explicit What-Does-NOT-Change preservation list
  problem_summary: How to make worktree-creating and branch-finishing skills work inside the Codex App sandbox without breaking Claude Code or Codex CLI behavior
  why_exemplar: Empirical-evidence-driven design with a sandbox-capabilities test table, an explicit decision matrix, and a Scope Summary table counting added lines per file

- file: 2026-04-06-worktree-rototill-design.md
  topic: Detect-and-defer rework of worktree management to prefer native harness tools across platforms
  domain: cross-harness skill design
  scale: large
  characteristics:
    - Goals/Non-Goals split plus named Design Principles section
    - cross-harness validation table (Claude Code, Codex, Gemini, Cursor, OpenCode)
    - TDD-driven design revision documented inline
    - bundled bug-fix table linking issue numbers to fixes
    - Risks section with status updates and residual risks
  problem_summary: How to make worktree management defer to each harness's native tools when present while keeping a working git fallback and fixing three finishing bugs
  why_exemplar: Goals/Non-Goals split, named Design Principles, cross-harness validation matrix, and a Risks section that documents both validated and residual concerns
