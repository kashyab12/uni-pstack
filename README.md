# uni-pstack

Portable pstack skill package for Codex and Claude Code.

This ports the Cursor pstack workflow into one standard skill folder:

- `pstack/SKILL.md` is the entry point.
- `pstack/references/` contains principles, playbooks, delegation, writing, and install guidance.
- `pstack/references/codex-cli.md` contains direct Codex CLI examples for foreground, background, review, resume, and long-running work.
- `pstack/scripts/spawn-codex-worker.sh` lets Claude Code launch Codex CLI workers for pstack subagent work.
- `install.sh` installs the skill into Codex, Claude Code, or both.

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

Claude Code should delegate pstack subagent work through Codex CLI workers:

```bash
pstack/scripts/spawn-codex-worker.sh --cwd "$PWD" --output ".pstack/workers/worker.md" -- "Task prompt"
```

Source inspiration: Cursor's MIT-licensed `pstack` plugin at <https://github.com/cursor/plugins/tree/main/pstack>.
