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

Port it as two host workflows:

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
