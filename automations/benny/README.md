# benny

benny gives you two cursor automations for slack issue reports. one triages each report. the other reproduces confirmed bugs and may prepare a small draft fix.

the files in this directory are setup and automation sources. they do not appear as slash skills.

## codex and claude code

this pack can be run through codex or claude code with the native portable runner. do not install these files unchanged as normal skills. the runner translates the trigger, waits, integration writes, and editor handoff into a codex cli job with durable prompt, output, and log files. the portable mapping lives at [`../../pstack/references/automations.md`](../../pstack/references/automations.md).

dry-run a triage prompt:

```bash
automations/benny/scripts/run.sh triage \
  --repo "$PWD" \
  --config .cursor/benny/configuration.yaml \
  --source-channel C123 \
  --message-ts 1712345678.000100 \
  --dry-run
```

run reproduce in the background:

```bash
automations/benny/scripts/run.sh reproduce \
  --repo "$PWD" \
  --config .cursor/benny/configuration.yaml \
  --source-channel C123 \
  --message-ts 1712345678.000100 \
  --background --json
```

when installed, the same runner is available at `~/.codex/skills/pstack/automations/benny/scripts/run.sh` and `~/.claude/skills/pstack/automations/benny/scripts/run.sh`. the claude path still launches codex cli.

## set it up

1. point cursor at [`FOR_AGENTS.md`](./FOR_AGENTS.md) and name the target repository.
2. let setup merge this whole directory into the target at `.cursor/automations/benny/`. it must preserve destination-only files and review conflicts instead of overwriting local edits.
3. let setup enable pstack in the target repository's `.cursor/settings.json` for shared dependencies:

```json
{
	"plugins": {
		"pstack": { "enabled": true }
	}
}
```

4. keep user-owned configuration outside the copied pack, for example in `.cursor/benny/`. adapt [`configuration.example.yaml`](./templates/configuration.example.yaml) and [`feature-map.example.md`](./skills/reproduce-and-fix-issues/references/feature-map.example.md).
5. commit `.cursor/settings.json`, `.cursor/automations/benny/`, and any secret-free configuration before enabling either automation.
6. review each new automation draft or update existing automations in their editors. then send a harmless test report and verify every source-channel post stays in the original thread.

## update

from the uni-pstack repository, refresh upstream-managed benny files:

```bash
scripts/update-from-upstream.sh
```

then update installed codex and claude code copies:

```bash
./install.sh --all --force
```
