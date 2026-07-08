# uni-pstack

Portable pstack skill package for Codex and Claude Code.

This ports the Cursor pstack workflow into a portable skill suite:

- `pstack/SKILL.md` is the entry point.
- `skills/` contains the upstream pstack subskills, including `architect`, `arena`, `how`, `why`, `interrogate`, `reflect`, `tdd`, `typescript-best-practices`, `unslop`, and the principle skills.
- `agents/poteto-agent.md` keeps the upstream agent shape as a portable reference. The installed `pstack/agents/poteto-agent.md` copy travels with the `pstack` skill.
- `automations/benny/` preserves the upstream Benny automation pack. Use `pstack/references/automations.md` to convert it into Codex or Claude Code runners.
- `pstack/references/` contains principles, playbooks, delegation, writing, and install guidance.
- `pstack/references/automations.md` maps Cursor automation concepts to Codex and Claude Code execution.
- `pstack/references/codex-cli.md` contains direct Codex CLI examples for foreground, background, review, resume, and long-running work.
- `pstack/scripts/spawn-codex-worker.sh` lets Claude Code launch Codex CLI workers for pstack subagent work.
- `install.sh` installs the full suite into Codex, Claude Code, or both.
- `scripts/validate.sh` runs the repeatable repo validation: upstream skill parity, skill frontmatter validation, shell parse checks, and install smoke tests.

Install locally. In a human terminal this shows Codex and Claude Code as options with both selected by default:

```bash
./install.sh
```

Automation:

```bash
./install.sh --all --yes
```

Install only one target:

```bash
./install.sh --codex
./install.sh --claude
```

Use it:

```text
Use $pstack to fix this bug with Codex subagents.
```

You can also invoke routed subskills directly after install:

```text
Use $architect to design this boundary before implementation.
Use $arena to compare three approaches.
Use $interrogate to pressure-test this diff.
```

Claude Code should delegate pstack subagent work through Codex CLI workers:

```bash
~/.claude/skills/pstack/scripts/spawn-codex-worker.sh --cwd "$PWD" --output ".pstack/workers/worker.md" -- "Task prompt"
```

Source inspiration: Cursor's MIT-licensed `pstack` plugin at <https://github.com/cursor/plugins/tree/main/pstack>.
