# Delegation

Use delegation to increase independent coverage without losing ownership. The parent agent owns the result, reviews artifacts, and writes the final summary.

## Executor Routing

In Claude Code, a Fable-class parent orchestrates and Codex executes by default. Classify each delegable unit of work before spawning; do not ask the user which executor to use.

- Default executor: Codex CLI worker, `gpt-5.6-sol`, task-appropriate reasoning capped at medium, fast tier. Use low for routine implementation and read-only exploration. Use medium for architecture, judgment, synthesis, ambiguous debugging, performance analysis, migrations, security-sensitive work, and other high-risk changes. Never request high or xhigh on `gpt-5.6-sol`.
- UI/UX exception: Codex is not the executor. The Fable parent implements it directly, or spawns a Claude-only worker per the Model Policy below. Applies to visual layout, styling and CSS, component and design-system work, animation and interaction feel, information hierarchy, UX flows and microcopy, and anything judged by how it looks or feels on screen.
- Mixed tasks: split at the boundary. Codex owns the logic slice (state, data, handlers, API); Fable owns the visual slice (markup structure, styling, interaction polish). Give each slice a disjoint file scope.
- Boundary calls: a frontend file is not automatically UI/UX. Wiring a hook, fixing a data bug in a component, or typing props is Codex work. Choosing spacing, color, motion, or copy is Fable work.

## Codex Native Subagents

When running inside Codex and a native multi-agent/subagent tool is available, use it for pstack delegation.

Default spawn shape for Codex-hosted pstack:

```text
agent_type: worker or explorer
model: gpt-5.6-sol
reasoning_effort: low for routine work; medium for judgment, synthesis, or high-risk work (never high or xhigh on gpt-5.6-sol)
service_tier: fast, if supported by this Codex build
fork_context: false unless the worker truly needs the full current thread
```

Omit `model`, `reasoning_effort`, or `service_tier` when the tool says to inherit from the parent or when the override is not supported. Some Codex native subagent builds expose `priority` rather than `fast` for `gpt-5.6-sol`; use the supported fast/priority tier and say which one was used. An explicit user choice wins, except that `gpt-5.6-sol` never runs above medium. If the host cannot set reasoning per task, use medium. Escalate low to medium after a failed attempt or when the task proves broader or riskier than classified; do not escalate past medium on `gpt-5.6-sol`.

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

- Codex-hosted pstack: use Codex native subagents with `gpt-5.6-sol`, task-appropriate reasoning capped at medium, and the supported fast/priority tier.
- Claude-hosted pstack, Codex delegation: use the bundled launcher with `gpt-5.6-sol`, automatic reasoning routing (low or medium only), and `service_tier="fast"` when supported.
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

The launcher resolves `worker` and `explorer` to low. It resolves `judge`, `architect`, `critic`, `reviewer`, and `synthesizer` to medium. Pass `--reasoning low` or `--reasoning medium` to override this routing. The launcher clamps `high` and `xhigh` to medium for `gpt-5.6-sol`.

Or call Codex directly:

```bash
codex exec \
  --cd "$PWD" \
  --model "${PSTACK_CODEX_MODEL:-gpt-5.6-sol}" \
  -c model_reasoning_effort='"low"' \
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
