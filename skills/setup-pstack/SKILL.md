---
name: setup-pstack
description: Configure uni-pstack Codex delegation defaults and host environment for Codex and Claude Code. Use for /setup-pstack, "configure pstack models", "set pstack to gpt 5.5 high fast", or changing pstack's Codex model choices.
---

# Setup pstack

Configure host-neutral uni-pstack defaults. Do not write Cursor rule files or rely on Cursor `Task` model slugs.

## Defaults

- Codex-hosted pstack: use native Codex subagents with `gpt-5.5`, high reasoning, and the supported fast or priority tier.
- Claude Code-hosted pstack: delegate pstack subagent work to Codex CLI workers with `gpt-5.5`, high reasoning, and `fast` when the local Codex CLI accepts it.
- Claude-only fallback policy is host-specific and lives in the installed pstack delegation reference. Do not apply Claude-only model rules inside Codex-hosted runs.

## Configuration file

Use `${XDG_CONFIG_HOME:-$HOME/.config}/uni-pstack/models.env` as the portable override file. It is a shell env file for humans and launch scripts, not a required runtime dependency.

Create the directory if missing and write only assignments the host can honor:

```bash
PSTACK_CODEX_MODEL=gpt-5.5
PSTACK_CODEX_REASONING=high
PSTACK_CODEX_SERVICE_TIER=fast
```

Optional Claude-only fallback values belong in the host's Claude configuration, not in Codex-hosted pstack runs. See the installed pstack delegation reference.

If a local Codex CLI rejects `PSTACK_CODEX_SERVICE_TIER=fast`, remove that line or set the closest supported tier. Preserve `gpt-5.5` and high reasoning unless the account does not expose that model.

## Steps

1. Detect the host: Codex, Claude Code, or a human shell setup.
2. Load the existing `models.env` if present. Treat absent values as the defaults above.
3. If the user asked for a specific model or tier, verify it by running the relevant CLI or by attempting a harmless dry-run command when available. Never write a value known to fail locally.
4. Write `models.env` idempotently. Keep it small and comment-free so it can be sourced directly.
5. For Claude Code, tell the user to source it before launching workers, or to prefix one run:

```bash
. "${XDG_CONFIG_HOME:-$HOME/.config}/uni-pstack/models.env"
~/.claude/skills/pstack/scripts/spawn-codex-worker.sh --cwd "$PWD" -- "Task prompt"
```

6. Confirm the active defaults in plain language:

- Codex workers: model, reasoning, and service tier.
- Claude-only fallback: report only when the host is Claude Code and the user explicitly configured one.

## Role mapping

Unless a host-specific tool supports per-role model overrides, every pstack role uses the same Codex default:

```text
feature, refactoring: gpt-5.5 high
bug-fix: gpt-5.5 high
perf-issue: gpt-5.5 high
hillclimb: gpt-5.5 high
judgment and prose: gpt-5.5 high
how explorer: gpt-5.5 high
how explainer: gpt-5.5 high
how critics: gpt-5.5 high, gpt-5.5 high, gpt-5.5 high
why investigators: gpt-5.5 high
why synthesizer: gpt-5.5 high
reflect tooling: gpt-5.5 high
reflect judgment, divergent, synthesizer: gpt-5.5 high
arena runners: gpt-5.5 high, gpt-5.5 high, gpt-5.5 high
architect runners: gpt-5.5 high, gpt-5.5 high, gpt-5.5 high
interrogate reviewers: gpt-5.5 high, gpt-5.5 high, gpt-5.5 high
```

Do not create `.cursor/rules/pstack-models.mdc`. That was upstream Cursor behavior and is not portable.
