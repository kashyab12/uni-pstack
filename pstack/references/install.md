# Installation

This skill is intentionally portable. The same `pstack/` folder works in Codex and Claude Code because it uses standard `SKILL.md` frontmatter with `name` and `description`.

## Codex

Install for all Codex projects:

```bash
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills"
cp -R /path/to/uni-pstack/pstack "${CODEX_HOME:-$HOME/.codex}/skills/pstack"
```

Restart Codex, or start a new Codex session, then invoke:

```text
Use $pstack to fix this bug.
```

When pstack needs subagents in Codex, it should use native Codex subagents/multi-agent tools first. The default is `gpt-5.5` with high reasoning and the supported fast/priority tier. If the native tool only offers `priority` for `gpt-5.5`, use it and report that fallback. Do not apply Claude-only `fable-5` rules in Codex.

## Claude Code

Install for all Claude Code projects:

```bash
mkdir -p "$HOME/.claude/skills"
cp -R /path/to/uni-pstack/pstack "$HOME/.claude/skills/pstack"
```

Or commit it as a project skill:

```bash
mkdir -p .claude/skills
cp -R /path/to/uni-pstack/pstack .claude/skills/pstack
```

Restart Claude Code or run a fresh `claude` session, then invoke:

```text
/pstack fix this bug. Use Codex subagents.
```

Claude Code skill docs define personal skills under `~/.claude/skills/<name>/SKILL.md` and project skills under `.claude/skills/<name>/SKILL.md`. The folder name becomes `/pstack`.

## Claude Uses Codex Workers

For Claude installations, pstack delegation must launch Codex CLI workers. Use:

```bash
~/.claude/skills/pstack/scripts/spawn-codex-worker.sh --cwd "$PWD" --output ".pstack/workers/worker.md" -- "Task prompt"
```

The launcher defaults:

```text
PSTACK_CODEX_MODEL=gpt-5.5
PSTACK_CODEX_REASONING=high
PSTACK_CODEX_SERVICE_TIER=fast
```

Override them only if the local Codex account uses a different slug for GPT-5.5:

```bash
PSTACK_CODEX_MODEL=gpt-5.5 PSTACK_CODEX_REASONING=high \
  ~/.claude/skills/pstack/scripts/spawn-codex-worker.sh -- "Task prompt"
```

Codex can run longer than 10 minutes. Use output files, JSONL logs, PIDs for background jobs, and wait patiently. See [codex-cli.md](codex-cli.md) for direct CLI examples.

## One-Command Local Install

From this repository:

```bash
pstack/scripts/install.sh
```

In an interactive terminal, the installer shows Codex and Claude Code as options with both selected by default. Press Enter to install both.

For automation, use explicit flags:

```bash
pstack/scripts/install.sh --all --yes
```

Use one target if needed:

```bash
pstack/scripts/install.sh --codex
pstack/scripts/install.sh --claude
```

Replace an existing install:

```bash
pstack/scripts/install.sh --all --force
```

Preview without writing files:

```bash
pstack/scripts/install.sh --all --dry-run
```

Override destinations:

```bash
pstack/scripts/install.sh --codex --codex-dir "$HOME/.codex/skills/pstack"
pstack/scripts/install.sh --claude --claude-dir ".claude/skills/pstack"
```

## Verify

Codex:

```bash
test -f "${CODEX_HOME:-$HOME/.codex}/skills/pstack/SKILL.md"
```

Claude Code:

```bash
test -f "$HOME/.claude/skills/pstack/SKILL.md"
```

Codex CLI:

```bash
codex --version
codex exec --help
```
