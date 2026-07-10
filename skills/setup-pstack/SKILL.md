---
name: setup-pstack
description: Configure uni-pstack Codex delegation defaults and host environment for Codex and Claude Code. Use for /setup-pstack, "configure pstack models", "set pstack reasoning", or changing pstack's Codex model choices.
---

# Setup pstack

Configure host-neutral uni-pstack defaults. Do not write Cursor rule files or rely on Cursor `Task` model slugs.

## Defaults

- Codex-hosted pstack: use native Codex subagents with `gpt-5.6-sol`, task-appropriate reasoning, and the supported fast or priority tier.
- Claude Code-hosted pstack: delegate pstack subagent work to Codex CLI workers with `gpt-5.6-sol`, task-appropriate reasoning, and `fast` when the local Codex CLI accepts it.
- Automatic routing uses low reasoning for routine implementation and exploration. It uses medium for judgment, synthesis, high-risk work, or an unknown role. `gpt-5.6-sol` is capped at medium; never request high or xhigh, and the launcher clamps them down.
- Claude-only fallback policy is host-specific and lives in the installed pstack delegation reference. Do not apply Claude-only model rules inside Codex-hosted runs.

## Configuration file

Use `${XDG_CONFIG_HOME:-$HOME/.config}/uni-pstack/models.env` as the portable override file. It is a shell env file for humans and launch scripts, not a required runtime dependency.

Create the directory if missing and write only assignments the host can honor:

```bash
PSTACK_CODEX_MODEL=gpt-5.6-sol
PSTACK_CODEX_REASONING=auto
PSTACK_CODEX_SERVICE_TIER=fast
```

Optional Claude-only fallback values belong in the host's Claude configuration, not in Codex-hosted pstack runs. See the installed pstack delegation reference.

Set `PSTACK_CODEX_REASONING` to `low` or `medium` to override routing for every worker. An explicit user choice or `--reasoning` flag wins over `auto`, except that the launcher clamps `high` and `xhigh` to medium for `gpt-5.6-sol`.

If a local Codex CLI rejects `PSTACK_CODEX_SERVICE_TIER=fast`, remove that line or set the closest supported tier. Preserve `gpt-5.6-sol` and the selected reasoning level unless the account does not expose that model.

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

- Codex workers: model, automatic reasoning policy or explicit override, and service tier.
- Claude-only fallback: report only when the host is Claude Code and the user explicitly configured one.

## Role mapping

Use these defaults when the host supports per-role reasoning. If it does not, use medium as the safe fallback. Escalate a low task to medium after a failed attempt or when investigation reveals high blast radius. `gpt-5.6-sol` never runs above medium; do not escalate to high or xhigh.

```text
feature, refactoring: gpt-5.6-sol low
bug-fix: gpt-5.6-sol low; medium when ambiguous or high risk
perf-issue: gpt-5.6-sol medium
hillclimb: gpt-5.6-sol medium
judgment and final synthesis: gpt-5.6-sol medium
how explorer: gpt-5.6-sol low
how direct explainer: gpt-5.6-sol low
how synthesizer: gpt-5.6-sol medium
how critics: gpt-5.6-sol medium, gpt-5.6-sol medium, gpt-5.6-sol medium
why investigators: gpt-5.6-sol low
why synthesizer: gpt-5.6-sol medium
reflect tooling: gpt-5.6-sol medium
reflect judgment, divergent, synthesizer: gpt-5.6-sol medium
arena runners: gpt-5.6-sol low, gpt-5.6-sol low, gpt-5.6-sol low
arena judge: gpt-5.6-sol medium
architect runners: gpt-5.6-sol medium, gpt-5.6-sol medium, gpt-5.6-sol medium
interrogate reviewers: gpt-5.6-sol medium, gpt-5.6-sol medium, gpt-5.6-sol medium
```

Do not create `.cursor/rules/pstack-models.mdc`. That was upstream Cursor behavior and is not portable.
