# Automation Porting

Cursor automations can be converted to Codex and Claude Code workflows. Do not install Cursor automation files unchanged as normal skills. Translate their runtime contract.

## Runtime Mapping

| Cursor automation concept | Codex / Claude Code equivalent |
|---|---|
| Trigger | Human command, scheduled job, webhook runner, CI job, monitor, or app automation |
| Automation prompt | Skill or runner prompt that reads the committed operational file |
| Cursor integrations | Host MCP tools, app connectors, CLIs, or explicit adapter scripts |
| Cursor `Task` workers | Codex native subagents in Codex; Codex CLI workers from Claude Code |
| Waits and wakeups | Polling loop, scheduled check, monitor, or background worker with output files |
| Automations editor approval | Config review, dry run, and explicit enable step |
| Automation run output | Log file, issue comment, Slack thread reply, PR body, or decision log |

## Porting Steps

1. Preserve the upstream automation pack as source material.
2. Extract the invariant contract: trigger, inputs, writes, safety gates, configuration, and success markers.
3. Choose a host runner:
   - Codex: native automation/monitor/thread wakeup when available, or a script that invokes `codex exec`.
   - Claude Code: shell script, scheduled job, webhook handler, or manual command that invokes Claude Code and delegates pstack subwork to Codex CLI.
4. Replace Cursor integration calls with host MCP tools, app connectors, CLIs, or adapter scripts.
5. Keep one coordinator responsible for external writes. Workers may analyze, reproduce, or patch, but should not post to Slack, mutate trackers, or create PRs unless that is their explicit isolated job.
6. Store configuration outside the source pack. Keep secrets in the host secret manager or environment.
7. Run a dry run against harmless input before enabling a repeating trigger.

## Benny Conversion

`automations/benny/` is the upstream Cursor automation pack for Slack issue triage and reproduce/fix. It is the canonical source for a portable Benny conversion.

uni-pstack ships the portable conversion as a runner around that pack. The runner does not make the Benny operational files into slash skills; it renders the upstream prompt template, points the agent at the operational file, and launches Codex CLI with durable prompt, output, and log files.

After `install.sh`, the runner is bundled inside the installed pstack skill:

```bash
~/.codex/skills/pstack/automations/benny/scripts/run.sh triage \
  --repo "$PWD" \
  --config .cursor/benny/configuration.yaml \
  --source-channel C123 \
  --message-ts 1712345678.000100 \
  --dry-run
```

From Claude Code, use the Claude-installed copy:

```bash
~/.claude/skills/pstack/automations/benny/scripts/run.sh reproduce \
  --repo "$PWD" \
  --config .cursor/benny/configuration.yaml \
  --source-channel C123 \
  --message-ts 1712345678.000100 \
  --background --json
```

The Claude path still launches Codex CLI. Do not replace it with Claude subagents unless the user explicitly asks for a Claude-only worker.

The runner owns this data shape:

- Trigger: `source_channel_id`, `message_ts`, optional `thread_ts`.
- Config: a user-owned Benny YAML file outside the source pack.
- Pack: the copied or installed `automations/benny/` source.
- Prompt: rendered from the matching template and saved under `.pstack/benny/`.
- Execution: `codex exec` with `gpt-5.5`, high reasoning, and supported fast/priority tier unless overridden.
- Output: final message, optional JSONL log, optional PID file under `.pstack/benny/`.

Run it as two host workflows:

1. `benny-triage`
   - Trigger: new top-level issue report in the configured source channel, or a manual command that points at one source thread.
   - Reads: source thread, attachments, repository, tracker, routing map.
   - Writes: exactly one source-thread verdict and optional tracker create/update.
   - Safety: immutable source channel/thread coordinates; no root posts; no guessed tickets.

2. `benny-reproduce`
   - Trigger: same report or scheduled poll that waits for the trusted triage marker.
   - Reads: source thread, tracker issue, repository, feature map, UI control adapter.
   - Writes: operations status, optional source-thread repro result, optional draft PR.
   - Safety: no authored fix without confirmed UI repro; verify existing fixes instead of racing them; draft PR only.

Claude Code should not spawn Claude subagents for pstack work by default. Its Benny runner should launch Codex workers with `pstack/scripts/spawn-codex-worker.sh` or direct `codex exec`.

Codex should use native subagents when available. For long waits, use a monitor, background worker, or explicit resume path instead of assuming no output means failure.

## Updating

There are two update operations.

1. Refresh this repository from upstream Cursor pstack:

```bash
scripts/update-from-upstream.sh
```

This uses a sparse upstream checkout under `.external/cursor-plugins`, refreshes upstream-managed Benny operational files and templates, records the upstream revision, and runs validation. It preserves native uni-pstack runner files. It intentionally does not overwrite the ported `skills/` tree because those files require the uni-pstack runtime adapter.

2. Update installed Codex and Claude Code copies from this repository:

```bash
./install.sh --all --force
```

The installer copies `pstack/`, all ported subskills, and bundles `automations/benny/` inside the installed `pstack` skill. Existing installed copies are replaced only with `--force` or an explicit interactive confirmation.
