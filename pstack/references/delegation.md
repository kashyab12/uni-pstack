# Delegation

Use delegation to increase independent coverage without losing ownership. The parent agent owns the result, reviews artifacts, and writes the final summary.

## Codex Native Subagents

When running inside Codex and a native multi-agent/subagent tool is available, use it for pstack delegation.

Default spawn shape for Codex-hosted pstack:

```text
agent_type: worker or explorer
model: gpt-5.5
reasoning_effort: high
service_tier: fast, if supported by this Codex build
fork_context: false unless the worker truly needs the full current thread
```

Omit `model`, `reasoning_effort`, or `service_tier` when the tool says to inherit from the parent or when the override is not supported. Some Codex native subagent builds expose `priority` rather than `fast` for `gpt-5.5`; use the supported fast/priority tier and say which one was used. If the user explicitly asked for `gpt-5.5 high fast reasoning`, preserve `gpt-5.5` and `high`, then use the closest supported service tier.

Use `worker` for bounded implementation. Specify:

- owned files or modules,
- success criteria,
- verification command,
- whether edits are allowed,
- instruction not to revert edits made by other workers,
- final output path or changed file list.

Use `explorer` for specific codebase questions. Ask concrete questions with file or symbol anchors. Do not ask broad research prompts that duplicate the parent work.

Do not wait reflexively. Spawn sidecar tasks, keep working locally, and wait only when the result is on the critical path.

## Model Policy

Upstream pstack mentions models such as Composer and Claude Opus. In this port:

- Codex-hosted pstack: use Codex native subagents with `gpt-5.5`, high reasoning, and the supported fast/priority tier.
- Claude-hosted pstack, Codex delegation: use Codex CLI with `gpt-5.5`, high reasoning, and `service_tier="fast"` when supported.
- Claude-hosted pstack, Claude-only workers: use Fable 5 high reasoning, with the exact model slug exposed by the local Claude CLI or host. For UI/UX Claude-only workers, use Fable 5 high for hard design decisions and medium for cheaper visual iteration.
- Do not apply `fable-5` guidance inside Codex-hosted pstack runs. Codex should not spawn Claude CLI workers by default.

## Claude Code To Codex Workers

Claude Code should delegate pstack subagent work to Codex, not ordinary Claude subagents. Use the bundled launcher:

```bash
pstack/scripts/spawn-codex-worker.sh \
  --role worker \
  --cwd "$PWD" \
  --output ".pstack/workers/worker-1.md" \
  -- \
  "Implement the bounded task here. Own files: src/foo.ts. Verify with npm test -- foo."
```

Or call Codex directly:

```bash
codex exec \
  --cd "$PWD" \
  --model "${PSTACK_CODEX_MODEL:-gpt-5.5}" \
  -c model_reasoning_effort='"high"' \
  -c service_tier='"fast"' \
  --output-last-message ".pstack/workers/worker-1.md" \
  "Task prompt"
```

For read-only investigation, add `--sandbox read-only`. For write work, use the repository's normal sandbox policy or `workspace-write`. Avoid bypassing approvals and sandboxing unless the environment is already externally sandboxed and the user requested unattended automation.

For clinical direct CLI examples, read [codex-cli.md](codex-cli.md). Prefer those examples over plugin slash-command wrappers.

## Long-Running Codex

Codex can legitimately run for more than 10 minutes.

- Use `--output-last-message` so the final response lands in a file.
- Use `--json` when a caller needs progress events or machine-readable logs.
- Store logs under `.pstack/workers/` or `/tmp/pstack-<slug>/`.
- Wait in minutes, not seconds. Do not kill a worker solely because there is no new stdout.
- If a session persists and needs continuation, use `codex exec resume --last` or the session id. For interactive lineage, use `codex resume` or `codex fork`.

## Arena

Arena means N independent candidates, then synthesis.

1. Frame one prompt and one rubric.
2. Give every candidate its own output path or worktree.
3. Run candidates in parallel.
4. Run one judge after candidates finish. The judge sees the rubric and outputs by label.
5. Parent reads every candidate, compares with the judge, picks a base, grafts only coherent ideas, and verifies.

Never let candidates write to the same branch or file set unless the task is intentionally serialized.

## Worker Prompt Template

```text
You are a pstack Codex worker.

Goal: <bounded goal>
Repository: <path>
Owned scope: <files/modules>
Do not touch: <files/modules>
Data shape/invariant: <shape>
Success criteria: <checkable criteria>
Verification: <commands or artifact checks>

You are not alone in the codebase. Do not revert edits made by others. If you see conflicting work, adapt and report it.

Return:
- files changed,
- what you did,
- verification result,
- risks or blockers.
```

## Parent Review

Treat worker output as a patch, not proof. Inspect the diff, run the verification, and own the final explanation. If a worker's result is good but too broad, narrow it before merging. If it violates the owned scope, revert or isolate that part.
