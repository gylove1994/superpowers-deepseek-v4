# Superpowers DeepSeek v4

**Superpowers DeepSeek v4** is an agentic methodology and composable skills library for coding agents. It evolved from ideas in [obra/superpowers](https://github.com/obra/superpowers) but is **maintained independently**. Skills, hooks, install paths, and release cadence **are not guaranteed to match** the upstream project. Report issues and open pull requests **in this repository** if you use this variant.

## Quickstart

Install for your harness: [Claude Code](#claude-code) · [Codex CLI](#codex-cli) · [Codex App](#codex-app) · [Factory Droid](#factory-droid) · [Gemini CLI](#gemini-cli) · [OpenCode](#opencode) · [Cursor](#cursor) · [GitHub Copilot CLI](#github-copilot-cli)

## How it works

When you start building something, the agent does not immediately jump into code. It steps back, clarifies intent, and turns the conversation into a design you can read in sections. After you approve the design, it produces an implementation plan that a careful junior engineer could follow. It emphasizes red/green TDD, YAGNI, and DRY. When you say go, skills like **subagent-driven-development** drive execution with reviews and checkpoints. Skills are designed to trigger automatically—no manual “turn on superpowers” step.

## Installation

Use **this repository** (`gylove1994/superpowers-deepseek-v4`) when copying install commands below. If you want the **upstream** [obra/superpowers](https://github.com/obra/superpowers) plugin instead, follow that project’s README; behavior and skills may differ.

### Claude Code (this repo — recommended)

From a clone of this repository, register the local marketplace and install the project-scoped plugin (see [.claude-plugin/marketplace.json](.claude-plugin/marketplace.json)):

```bash
cd /path/to/superpowers-deepseek-v4
/plugin marketplace add ./
/plugin install superpowers@gylove1994-superpowers-deepseek-v4 --scope project
```

Or add `--scope user` if you want it available in every project.

#### Upstream reference (official Superpowers plugin)

Anthropic’s catalog entry is not this fork. To install **upstream** Superpowers only:

```bash
/plugin install superpowers@claude-plugins-official
```

### Codex CLI

Use the [official Codex plugin marketplace](https://github.com/openai/plugins). Search for Superpowers and install; confirm the package points at **this** repo if you intend to use DeepSeek v4–oriented skills.

```bash
/plugins
# search: superpowers
```

### Codex App

Same marketplace as Codex CLI: Plugins → find Superpowers → install. Verify source matches the repository you intend.

### Factory Droid

```bash
droid plugin marketplace add https://github.com/gylove1994/superpowers-deepseek-v4
droid plugin install superpowers@superpowers
```

(Adjust plugin id if your marketplace entry uses a different name.)

### Gemini CLI

```bash
gemini extensions install https://github.com/gylove1994/superpowers-deepseek-v4
gemini extensions update superpowers
```

### OpenCode

OpenCode has its own install path. Use the copy of **this** repo’s instructions:

```text
Fetch and follow instructions from https://raw.githubusercontent.com/gylove1994/superpowers-deepseek-v4/main/.opencode/INSTALL.md
```

More detail: [.opencode/INSTALL.md](.opencode/INSTALL.md) and [docs/README.opencode.md](docs/README.opencode.md).

### Cursor

In Cursor Agent chat:

```text
/add-plugin superpowers
```

Or search the marketplace for this project’s listing, if published.

### GitHub Copilot CLI

The default community marketplace ships the **upstream** Superpowers plugin. To use **this** repository, add a marketplace or install path that references `https://github.com/gylove1994/superpowers-deepseek-v4` (see GitHub Copilot CLI plugin docs for `marketplace add` / `plugin install` with a custom source). Example pattern if you mirror this repo into a marketplace entry:

```bash
copilot plugin marketplace add <YOUR_MARKETPLACE_OR_PATH_TO_THIS_REPO>
copilot plugin install superpowers@<YOUR_ENTRY>
```

Verify the resolved plugin URL points at this fork before relying on DeepSeek v4–oriented behavior.

## The Basic Workflow

1. **brainstorming** — Before code: questions, alternatives, design in readable chunks; saves the design doc.
2. **confirming-worktree-before-edit** → **using-git-worktrees** — Session bootstrap (before using-superpowers): confirm worktree preference once per session before any project file write (source, spec, plan, config), then isolated branch/workspace and clean test baseline when accepted.
3. **writing-plans** — Turns the approved design into small tasks with paths and verification.
4. **subagent-driven-development** or **executing-plans** — Executes the plan with reviews or batch checkpoints.
5. **test-driven-development** — RED–GREEN–REFACTOR; failures first, minimal code, then refactor.
6. **requesting-code-review** — Between tasks; severity and blockers.
7. **finishing-a-development-branch** — Done: tests, merge/PR/keep/discard, worktree cleanup.

The agent is expected to invoke relevant skills before and during work—this is workflow, not optional flavor text.

## What's Inside

### Skills library (high level)

**Testing** — **test-driven-development**

**Debugging** — **systematic-debugging**, **verification-before-completion**

**Collaboration** — **brainstorming**, **writing-plans**, **executing-plans**, **dispatching-parallel-agents**, **requesting-code-review**, **receiving-code-review**, **confirming-worktree-before-edit**, **using-git-worktrees**, **finishing-a-development-branch**, **subagent-driven-development**

**Meta** — **writing-skills**, **using-superpowers**

## Philosophy

- Test-driven development first
- Systematic investigation over guessing
- Simplicity as a goal
- Verify before claiming done

Background on the original Superpowers announcement: [blog.fsck.com (Oct 2025)](https://blog.fsck.com/2025/10/09/superpowers/).

## Contributing

Contributions go through **this** repository. New skills and cross-harness behavior are reviewed strictly (see [CLAUDE.md](CLAUDE.md) and the PR template). Typical flow:

1. Fork or branch from this repo  
2. Use the `writing-skills` skill for skill changes  
3. Open **one** focused PR with the template fully filled  

## Updating

Plugin and harness updates vary by tool; some update automatically when you refresh marketplace or git-backed installs.

## License

MIT — see [LICENSE](LICENSE).

## Community & attribution

Maintained by [gylove1994](https://github.com/gylove1994). The original **Superpowers** project was created by [Jesse Vincent](https://blog.fsck.com) and [Prime Radiant](https://primeradiant.com). This fork appreciates that lineage; it does not imply endorsement or feature parity.

- **Issues (this project):** https://github.com/gylove1994/superpowers-deepseek-v4/issues  
- **Upstream project (reference):** https://github.com/obra/superpowers  

Discord and release lists aimed at the upstream community may still be useful for general discussion; they are not the support channel for **this** fork’s behavior.
