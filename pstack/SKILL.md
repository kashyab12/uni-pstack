---
name: pstack
description: "Portable pstack engineering workflow for Claude Code and Codex. Use for /pstack, poteto-mode style work, rigorous multi-step coding tasks, bug fixes, investigations, refactors, features, performance work, skill authoring, reviews, autonomous runs, arena-style parallel attempts, updating pstack itself, or any request that should use Codex subagents, Codex CLI workers, explicit verification, and concise unslopped engineering prose."
---

# pstack

pstack is a rigorous engineering workflow ported from Cursor's pstack/poteto-mode ideas for Claude Code and Codex. It optimizes for small, correct, verified changes and deliberate parallelism.

## Start Protocol

For any multi-step task:

1. Open a todo list or plan. The first item is `Read pstack principles`.
2. Read [principles.md](references/principles.md) before choosing the implementation shape.
3. Classify the request with [playbooks.md](references/playbooks.md), then copy the matched playbook steps into the todo list before adding task-specific items.
4. Read [delegation.md](references/delegation.md) before spawning any subagent, worker, arena candidate, judge, or long-running helper.
5. Read [codex-cli.md](references/codex-cli.md) when using Codex from a shell, especially from Claude Code.
6. Read [writing.md](references/writing.md) before the final reply, PR text, commit body, or any agent-facing prose.

If the request is only installation, configuration, or packaging, read [install.md](references/install.md) instead of the full playbook set.

## Update Protocol

When asked to update pstack, uni-pstack, this skill, or installed pstack copies:

1. Prefer the bundled updater:
   ```bash
   pstack/scripts/update-self.sh
   ```
   From an installed Codex copy this is usually `${CODEX_HOME:-$HOME/.codex}/skills/pstack/scripts/update-self.sh`. From Claude Code this is usually `~/.claude/skills/pstack/scripts/update-self.sh`.
2. If already inside the uni-pstack source repository, use:
   ```bash
   ./install.sh --update
   ```
3. Narrow the target only when requested:
   ```bash
   ./install.sh --update --codex
   ./install.sh --update --claude
   ```
4. After updating, run or cite the verification from [install.md](references/install.md). If the source repo changed, run `scripts/validate.sh` before reporting success.

## Non-Negotiables

- For code, name the data shape first. The shape may be a type, schema, protocol, state machine, file format, or invariant.
- For code crossing a function boundary, use the Architect flow in [playbooks.md](references/playbooks.md) unless the skip reason is explicit and visible in the todo list.
- For contested or high-blast-radius designs, run Arena or Interrogate before shipping.
- For bug fixes and performance work, reproduce or measure first. Do not ship a speculative guard.
- For refactors, pin the behavior contract before moving structure.
- For UI, CLI, IDE, or runtime behavior, verify on the matching surface. A test or type check is useful but is not the whole proof.
- For long or autonomous work, keep an audit trail with decisions, evidence, and verification commands.
- Before declaring done, prove the real artifact works. Trust artifacts, not self-reports from workers.
- Ask the human only for irreversible actions or genuine product preference. Reversible engineering work proceeds with a clear record.

## Delegation Defaults

pstack uses Codex for delegated work.

- In Codex, use native Codex subagents/multi-agent tools when available. Prefer `worker` for bounded code changes and `explorer` for specific read-only codebase questions.
- In Claude Code, use Codex CLI workers via `scripts/spawn-codex-worker.sh` or direct `codex exec` for pstack Codex delegation. Do not replace pstack's Codex delegation with ordinary Claude subagents unless the task explicitly needs a Claude model.
- Codex delegation default: `gpt-5.6-sol`, task-appropriate reasoning, and the supported fast/priority tier. Use medium for routine workers and explorers; use high for judgment, synthesis, high-risk work, and unknown roles. This replaces upstream pstack's Composer/Claude Opus model defaults.
- UI/UX exception in Claude Code: Codex does not execute UI/UX work (layout, styling, component design, interaction feel, UX flows, microcopy). The Fable parent implements it directly or spawns a Claude-only worker. Route per the Executor Routing section in [delegation.md](references/delegation.md); split mixed tasks at the logic/visual boundary.
- Claude-only fallback policy is host-specific and lives in [delegation.md](references/delegation.md). Do not apply Claude-only model rules inside Codex-hosted skill runs.
- Codex workers can take more than 10 minutes. Use long waits, output files, JSONL logs, and resume/fork commands instead of assuming silence means failure.
- Give every worker a disjoint write scope or its own worktree. Shared mutable state is a design problem, not a prompt problem.

## Installed Subskills

This repo installs the universal `pstack` skill plus upstream-derived subskills under `skills/`. After installation, route to these directly when the user asks for them or when the playbook calls for them:

- `architect`, `arena`, `blast-radius`, `figure-it-out`, `how`, `why`, `interrogate`, `reflect`, `recall`, `show-me-your-work`, `tdd`, `typescript-best-practices`, `unslop`.
- `poteto-mode` remains available as the closest upstream mode skill, with the uni-pstack runtime adapter applied.
- Principle skills are installed individually as `principle-*` so routed skills can reference and load the full rule when needed.

## Resource Map

- [principles.md](references/principles.md): the principle index and concrete rules.
- [playbooks.md](references/playbooks.md): routing table and execution steps.
- [delegation.md](references/delegation.md): Codex subagents, Claude-to-Codex CLI, long waits, arena patterns.
- [codex-cli.md](references/codex-cli.md): direct Codex CLI cookbook with clinical examples.
- [automations.md](references/automations.md): native Benny runner, Cursor automation mapping, and update paths.
- [writing.md](references/writing.md): concise reply and prose cleanup rules.
- [install.md](references/install.md): installing this same skill for Codex and Claude Code.
- [scripts/spawn-codex-worker.sh](scripts/spawn-codex-worker.sh): portable Codex CLI worker launcher.

## Completion Contract

Every pstack run ends with:

- What changed or what was learned.
- The key decision and why it held.
- Verification against the real artifact, including commands or artifact paths.
- Open risks or gaps, if any.
- Paths to any decision trail, worker outputs, PRs, or scratch artifacts.
