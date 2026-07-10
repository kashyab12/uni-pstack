#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
upstream_dir="$repo_dir/.external/cursor-plugins/pstack"
validator="${CODEX_SKILL_VALIDATOR:-/Users/kashyab/.codex/skills/.system/skill-creator/scripts/quick_validate.py}"

fail() {
  printf 'validate.sh: %s\n' "$*" >&2
  exit 1
}

if [[ ! -d "$upstream_dir/skills" ]]; then
  fail "missing upstream clone at $upstream_dir; clone cursor/plugins into .external/cursor-plugins first"
fi

echo "== upstream skill parity =="
missing="$(comm -23 \
  <(cd "$upstream_dir/skills" && find . -type f | sort) \
  <(cd "$repo_dir/skills" && find . -type f | sort))"
extra="$(comm -13 \
  <(cd "$upstream_dir/skills" && find . -type f | sort) \
  <(cd "$repo_dir/skills" && find . -type f | sort))"
if [[ -n "$missing" || -n "$extra" ]]; then
  [[ -z "$missing" ]] || printf 'missing from skills/:\n%s\n' "$missing" >&2
  [[ -z "$extra" ]] || printf 'extra in skills/:\n%s\n' "$extra" >&2
  fail "skills/ no longer matches upstream pstack/skills"
fi
echo "skills/ matches upstream pstack/skills"

echo "== required upstream package material =="
test -f "$repo_dir/automations/benny/FOR_AGENTS.md"
test -x "$repo_dir/automations/benny/scripts/run.sh"
test -f "$repo_dir/agents/poteto-agent.md"
test -f "$repo_dir/pstack/agents/poteto-agent.md"
test -f "$repo_dir/pstack/references/automations.md"
test -f "$repo_dir/.cursor-plugin/plugin.json"

echo "== stale model/frontmatter scan =="
if rg -n 'claude-opus|composer-2\.5|(?i:gpt-5\.5)|gpt-5\.6-sol-high-fast|^disable-model-invocation:|^user-invocable:' \
  "$repo_dir/README.md" "$repo_dir/install.sh" "$repo_dir/pstack" "$repo_dir/skills" "$repo_dir/agents"; then
  fail "stale model names or non-portable installed-skill frontmatter found"
fi

echo "== skill validation =="
if [[ ! -f "$validator" ]]; then
  fail "skill validator not found: $validator"
fi
for skill in "$repo_dir/pstack" "$repo_dir"/skills/*; do
  [[ -f "$skill/SKILL.md" ]] || continue
  python3 "$validator" "$skill" >/dev/null
done
echo "all installed skills validate"

echo "== shell parse checks =="
bash -n "$repo_dir/install.sh"
bash -n "$repo_dir/pstack/scripts/spawn-codex-worker.sh"
bash -n "$repo_dir/pstack/scripts/update-self.sh"
bash -n "$repo_dir/automations/benny/scripts/run.sh"
bash -n "$repo_dir/scripts/update-from-upstream.sh"
bash -n "$repo_dir/skills/show-me-your-work/scripts/log.sh"

echo "== benny runner smoke =="
benny_tmp="$(mktemp -d)"
mkdir -p "$benny_tmp/repo/.cursor/benny"
cp "$repo_dir/automations/benny/templates/configuration.example.yaml" "$benny_tmp/repo/.cursor/benny/configuration.yaml"
"$repo_dir/automations/benny/scripts/run.sh" triage \
  --repo "$benny_tmp/repo" \
  --config "$benny_tmp/repo/.cursor/benny/configuration.yaml" \
  --source-channel C123 \
  --message-ts 1712345678.000100 \
  --dry-run >/tmp/uni-pstack-benny-prompt.md
test -f "$benny_tmp/repo/.pstack/benny/"*"-benny-triage.prompt.md"
rg -q 'Operational file to read and follow:' /tmp/uni-pstack-benny-prompt.md
rg -q '"source_channel_id":"C123"' /tmp/uni-pstack-benny-prompt.md

echo "== reasoning route smoke =="
explorer_route="$(PSTACK_CODEX_REASONING=auto "$repo_dir/pstack/scripts/spawn-codex-worker.sh" \
  --role explorer \
  --cwd "$benny_tmp/repo" \
  --output "$benny_tmp/explorer.md" \
  --dry-run -- "route check" 2>&1)"
worker_route="$(PSTACK_CODEX_REASONING=auto "$repo_dir/pstack/scripts/spawn-codex-worker.sh" \
  --role worker \
  --cwd "$benny_tmp/repo" \
  --output "$benny_tmp/worker.md" \
  --dry-run -- "route check" 2>&1)"
judge_route="$(PSTACK_CODEX_REASONING=auto "$repo_dir/pstack/scripts/spawn-codex-worker.sh" \
  --role judge \
  --cwd "$benny_tmp/repo" \
  --output "$benny_tmp/judge.md" \
  --dry-run -- "route check" 2>&1)"
override_route="$(PSTACK_CODEX_REASONING=high "$repo_dir/pstack/scripts/spawn-codex-worker.sh" \
  --role explorer \
  --cwd "$benny_tmp/repo" \
  --output "$benny_tmp/override.md" \
  --dry-run -- "route check" 2>&1)"
rg -q 'reasoning=low' <<<"$explorer_route"
rg -q 'reasoning=low' <<<"$worker_route"
rg -q 'reasoning=medium' <<<"$judge_route"
rg -q 'capped at medium' <<<"$override_route"
rg -q 'reasoning=medium' <<<"$override_route"
echo "reasoning routes resolve and gpt-5.6-sol clamps high to medium"

echo "== install smoke =="
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp" "$benny_tmp"' EXIT
HOME="$tmp/home" CODEX_HOME="$tmp/codex" "$repo_dir/install.sh" --all --yes >/tmp/uni-pstack-install.log
HOME="$tmp/home" CODEX_HOME="$tmp/codex" "$repo_dir/install.sh" --update >/tmp/uni-pstack-update.log
HOME="$tmp/home" CODEX_HOME="$tmp/codex" "$repo_dir/pstack/scripts/update-self.sh" --source "$repo_dir" --dry-run >/tmp/uni-pstack-self-update.log
test -f "$tmp/codex/skills/pstack/SKILL.md"
test -f "$tmp/codex/skills/pstack/agents/poteto-agent.md"
test -x "$tmp/codex/skills/pstack/scripts/update-self.sh"
test -x "$tmp/codex/skills/pstack/automations/benny/scripts/run.sh"
test -f "$tmp/codex/skills/pstack/automations/benny/FOR_AGENTS.md"
test -f "$tmp/codex/skills/architect/references/runner-prompt.md"
test -f "$tmp/codex/skills/poteto-mode/playbooks/opening-a-pr.md"
test -f "$tmp/codex/skills/why/references/sources/slack.md"
test -f "$tmp/home/.claude/skills/arena/SKILL.md"
count="$(find "$tmp/codex/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
[[ "$count" = 37 ]] || fail "expected 37 Codex skill folders, got $count"
rg -q 'Mode: update installed copies' /tmp/uni-pstack-update.log
rg -q 'would install Codex pstack' /tmp/uni-pstack-self-update.log
echo "install suite ok: $count skills"

echo "validation passed"
