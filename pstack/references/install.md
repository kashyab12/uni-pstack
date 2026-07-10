# Installation

This package is intentionally portable. It installs the universal `pstack/` entry skill plus the upstream-derived subskills under `skills/`. Every installed folder uses standard `SKILL.md` frontmatter with `name` and `description`.

The upstream Benny automation pack lives under `automations/benny/`. `install.sh` does not install those files as normal Codex or Claude Code skills because automation triggers, waits, and integration writes need a host runner. It does bundle the pack under the installed `pstack/automations/benny/` resource directory so Codex and Claude Code can run the native portable Benny runner. See [automations.md](automations.md).

## Codex

Install for all Codex projects:

```bash
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills"
./install.sh --codex
```

Restart Codex, or start a new Codex session, then invoke:

```text
Use $pstack to fix this bug.
```

When pstack needs subagents in Codex, it should use native Codex subagents/multi-agent tools first. The default is `gpt-5.6-sol` with low reasoning for routine work and exploration, medium reasoning for judgment and high-risk work, and the supported fast/priority tier. Never request high or xhigh on `gpt-5.6-sol`; medium is the cap. If the native tool only offers `priority` for `gpt-5.6-sol`, use it and report that fallback. Do not apply Claude-only model rules in Codex.

## Claude Code

Install for all Claude Code projects:

```bash
./install.sh --claude
```

Or commit it as a project skill:

```bash
./install.sh --claude --claude-dir .claude/skills
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
PSTACK_CODEX_MODEL=gpt-5.6-sol
PSTACK_CODEX_REASONING=auto
PSTACK_CODEX_SERVICE_TIER=fast
```

`auto` uses low for routine workers and explorers, and medium for judgment roles. The launcher clamps `high` and `xhigh` to medium for `gpt-5.6-sol`. Override it when the task needs a fixed level:

```bash
PSTACK_CODEX_MODEL=gpt-5.6-sol PSTACK_CODEX_REASONING=medium \
  ~/.claude/skills/pstack/scripts/spawn-codex-worker.sh -- "Task prompt"
```

Codex can run longer than 10 minutes. Use output files, JSONL logs, PIDs for background jobs, and wait patiently. See [codex-cli.md](codex-cli.md) for direct CLI examples.

## One-Command Local Install

From this repository:

```bash
./install.sh
```

In an interactive terminal, the installer shows Codex and Claude Code as options with both selected by default. Press Enter to install both.

For automation, use explicit flags:

```bash
./install.sh --all --yes
```

Use one target if needed:

```bash
./install.sh --codex
./install.sh --claude
```

Replace an existing install:

```bash
./install.sh --all --force
```

Update installed Codex and Claude Code copies from the current source repo:

```bash
./install.sh --update
```

Narrow the update if needed:

```bash
./install.sh --update --codex
./install.sh --update --claude
```

From an installed skill with no source checkout nearby, use the bundled self-updater. It keeps a shallow checkout under `${XDG_CACHE_HOME:-$HOME/.cache}/uni-pstack/source`, fetches `main`, then runs `install.sh --update`:

```bash
${CODEX_HOME:-$HOME/.codex}/skills/pstack/scripts/update-self.sh
~/.claude/skills/pstack/scripts/update-self.sh
```

Preview without writing files:

```bash
./install.sh --update --dry-run
```

Override skills directories:

```bash
./install.sh --codex --codex-dir "$HOME/.codex/skills"
./install.sh --claude --claude-dir ".claude/skills"
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

Benny runner:

```bash
test -x "${CODEX_HOME:-$HOME/.codex}/skills/pstack/automations/benny/scripts/run.sh"
```

Self-updater:

```bash
test -x "${CODEX_HOME:-$HOME/.codex}/skills/pstack/scripts/update-self.sh"
```
