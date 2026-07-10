# Codex CLI Cookbook

Use these examples when pstack is running from Claude Code or any shell that needs to drive Codex directly. Prefer direct `codex` commands over wrapper slash commands.

## Preflight

```bash
codex --version
codex doctor
codex login
codex exec --help
codex review --help
```

If `codex login` cannot open a browser, use the auth modes shown by `codex login --help`.

## Model and reasoning flags

Use low for routine implementation and exploration:

```bash
--model gpt-5.6-sol \
-c model_reasoning_effort='"low"' \
-c service_tier='"fast"'
```

Use medium for architecture, judgment, synthesis, ambiguous debugging, performance analysis, migrations, security-sensitive work, and other high-risk changes. Never set `high` or `xhigh` on `gpt-5.6-sol`; medium is the cap even when the user asks for more depth. If the local Codex build rejects `service_tier="fast"`, drop that config or use the closest supported tier.

## Foreground Read-Only Investigation

```bash
codex exec \
  --cd "$PWD" \
  --sandbox read-only \
  --model gpt-5.6-sol \
  -c model_reasoning_effort='"low"' \
  -c service_tier='"fast"' \
  --output-last-message ".pstack/workers/save-flow.md" \
  --json \
  "Map the Save click path end to end. Return files inspected, the state machine, likely no-op paths, and the next reproduction check."
```

Use `--sandbox read-only` for explorers. Reviews use medium reasoning — the `gpt-5.6-sol` cap — because they make judgment calls. Use `--json` when you want progress events in logs. Use `--output-last-message` for the final answer.

## Foreground Write Worker

```bash
codex exec \
  --cd "$PWD" \
  --sandbox workspace-write \
  --model gpt-5.6-sol \
  -c model_reasoning_effort='"low"' \
  -c service_tier='"fast"' \
  --output-last-message ".pstack/workers/save-fix.md" \
  "Fix the confirmed Save no-op bug.

Owned scope: src/save.ts, src/save-button.tsx.
Do not touch unrelated files.
Invariant: an accepted click either starts one save attempt, surfaces a blocking reason, or is disabled before click.
Verify with: pnpm test save-button.spec.ts.
Return touched files, fix summary, verification result, and risks."
```

Keep the prompt concrete. Name owned files, invariants, verification, and output contract.

## Piped Prompt

Use a heredoc when the prompt is long:

```bash
codex exec \
  --cd "$PWD" \
  --sandbox workspace-write \
  --model gpt-5.6-sol \
  -c model_reasoning_effort='"low"' \
  --output-last-message ".pstack/workers/fix.md" \
  - <<'PROMPT'
<task>
Implement the smallest safe fix for the confirmed bug.
</task>

<scope>
Owned files: src/save.ts, src/save-button.tsx.
Do not edit tests except the regression test named below.
</scope>

<verification>
Run pnpm test save-button.spec.ts.
</verification>

<output>
Return touched files, summary, verification, and residual risk.
</output>
PROMPT
```

## Background Worker

Use background execution for work that may run more than a few minutes.

```bash
mkdir -p .pstack/workers
nohup codex exec \
  --cd "$PWD" \
  --sandbox workspace-write \
  --model gpt-5.6-sol \
  -c model_reasoning_effort='"low"' \
  -c service_tier='"fast"' \
  --json \
  --output-last-message ".pstack/workers/fix.md" \
  "Fix the confirmed bug. Verify with pnpm test save-button.spec.ts." \
  > ".pstack/workers/fix.jsonl" 2>&1 &
echo $! > ".pstack/workers/fix.pid"
```

Check it without killing it:

```bash
ps -p "$(cat .pstack/workers/fix.pid)"
tail -n 80 ".pstack/workers/fix.jsonl"
test -s ".pstack/workers/fix.md" && sed -n '1,220p' ".pstack/workers/fix.md"
```

Cancel only when you have decided the run should stop:

```bash
kill "$(cat .pstack/workers/fix.pid)"
```

## Bundled Launcher

The pstack launcher wraps the foreground/background pattern and writes outputs under `.pstack/workers/`:

```bash
pstack/scripts/spawn-codex-worker.sh \
  --role worker \
  --cwd "$PWD" \
  --sandbox workspace-write \
  --background \
  --output ".pstack/workers/save-fix.md" \
  --log ".pstack/workers/save-fix.jsonl" \
  -- \
  "Fix the confirmed Save no-op bug. Verify with pnpm test save-button.spec.ts."
```

The launcher defaults to `auto`. Roles `worker` and `explorer` use low. Roles `judge`, `architect`, `critic`, `reviewer`, and `synthesizer` use medium. Pass `--reasoning low` or `--reasoning medium` to override the role default; the launcher clamps `high` and `xhigh` to medium for `gpt-5.6-sol`. Use `--dry-run` to inspect the resolved choice without starting Codex.

Read result:

```bash
cat ".pstack/workers/save-fix.md"
```

## Review Commands

Review uncommitted changes:

```bash
codex review --uncommitted
```

Review branch against main:

```bash
codex review --base main
```

Review a commit:

```bash
codex review --commit "$SHA"
```

Use a custom review prompt only when the built-in review target is not enough:

```bash
codex review --uncommitted "Focus on race conditions, stale state, rollback paths, and data loss."
```

## Resume And Fork

Continue the most recent interactive Codex session:

```bash
codex resume --last
```

Fork the most recent session for an alternate attempt:

```bash
codex fork --last
```

Continue the most recent non-interactive exec session when supported:

```bash
codex exec resume --last
```

Resume by id when Codex prints one:

```bash
codex resume <session-id>
codex exec resume <session-id>
```

Use resume for follow-up instructions on the same line of work. Use fork for an alternate design or second opinion.

## Apply Latest Diff

When a Codex session produced a patch that was not applied:

```bash
codex apply
```

Inspect the diff after applying:

```bash
git diff --stat
git diff
```

## Prompt Shape

Use compact XML blocks for complex tasks:

```xml
<task>
The concrete job and expected end state.
</task>

<scope>
Owned files, forbidden files, and allowed edit surface.
</scope>

<invariant>
The data shape or state machine that must hold.
</invariant>

<verification>
Commands or artifact checks Codex must run.
</verification>

<output>
Touched files, summary, verification, residual risks.
</output>
```

Do not pack unrelated jobs into one Codex run. Split review, fix, docs, and roadmap into separate runs.
