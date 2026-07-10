#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  run.sh triage|reproduce --repo DIR --config FILE --source-channel ID --message-ts TS [options]

Options:
  --thread-ts TS          Root thread timestamp. Defaults to --message-ts.
  --output FILE           Final Codex message path.
  --log FILE              JSONL/stdout log path for background runs.
  --pid-file FILE         PID path for background runs.
  --prompt-out FILE       Write the rendered prompt to this file.
  --dry-run               Render the prompt and exit without launching Codex.
  --background            Run Codex in the background.
  --json                  Ask Codex CLI for JSONL events.
  --sandbox MODE          Pass a Codex sandbox mode.
  --model MODEL           Default: PSTACK_CODEX_MODEL or gpt-5.6-sol.
  --reasoning LEVEL       Default: PSTACK_CODEX_REASONING or auto; auto resolves to medium.
                          gpt-5.6-sol is capped at medium; high/xhigh are clamped down.
  --service-tier TIER     Default: PSTACK_CODEX_SERVICE_TIER or fast.
  -h, --help              Show this help.

Examples:
  automations/benny/scripts/run.sh triage \
    --repo "$PWD" \
    --config .cursor/benny/configuration.yaml \
    --source-channel C123 \
    --message-ts 1712345678.000100 \
    --dry-run

  automations/benny/scripts/run.sh reproduce \
    --repo "$PWD" \
    --config .cursor/benny/configuration.yaml \
    --source-channel C123 \
    --message-ts 1712345678.000100 \
    --background --json
USAGE
}

die() {
  printf 'benny run: %s\n' "$*" >&2
  exit 1
}

abs_path() {
  local input="$1"
  if [[ "$input" = /* ]]; then
    printf '%s\n' "$input"
  elif [[ -e "$input" ]]; then
    (cd "$(dirname "$input")" && printf '%s/%s\n' "$(pwd)" "$(basename "$input")")
  else
    printf '%s/%s\n' "$(pwd)" "$input"
  fi
}

json_escape() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  printf '%s' "$value"
}

replace_all() {
  local text="$1"
  local needle="$2"
  local replacement="$3"
  printf '%s' "${text//${needle}/${replacement}}"
}

workflow="${1:-}"
if [[ "$workflow" == "-h" || "$workflow" == "--help" ]]; then
  usage
  exit 0
fi
[[ "$workflow" == "triage" || "$workflow" == "reproduce" ]] || {
  usage >&2
  exit 2
}
shift

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pack_dir="$(cd "$script_dir/.." && pwd)"

repo=""
config=""
source_channel=""
message_ts=""
thread_ts=""
output=""
log_file=""
pid_file=""
prompt_out=""
dry_run=0
background=0
json=0
sandbox="${PSTACK_CODEX_SANDBOX:-}"
model="${PSTACK_CODEX_MODEL:-gpt-5.6-sol}"
reasoning="${PSTACK_CODEX_REASONING:-auto}"
service_tier="${PSTACK_CODEX_SERVICE_TIER:-fast}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      repo="${2:?missing repository directory}"
      shift 2
      ;;
    --config)
      config="${2:?missing configuration path}"
      shift 2
      ;;
    --source-channel)
      source_channel="${2:?missing source channel id}"
      shift 2
      ;;
    --message-ts)
      message_ts="${2:?missing message timestamp}"
      shift 2
      ;;
    --thread-ts)
      thread_ts="${2:?missing thread timestamp}"
      shift 2
      ;;
    --output)
      output="${2:?missing output path}"
      shift 2
      ;;
    --log)
      log_file="${2:?missing log path}"
      shift 2
      ;;
    --pid-file)
      pid_file="${2:?missing pid path}"
      shift 2
      ;;
    --prompt-out)
      prompt_out="${2:?missing prompt output path}"
      shift 2
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    --background)
      background=1
      shift
      ;;
    --json)
      json=1
      shift
      ;;
    --sandbox)
      sandbox="${2:?missing sandbox mode}"
      shift 2
      ;;
    --model)
      model="${2:?missing model}"
      shift 2
      ;;
    --reasoning)
      reasoning="${2:?missing reasoning level}"
      shift 2
      ;;
    --service-tier)
      service_tier="${2:?missing service tier}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

case "$reasoning" in
  auto)
    reasoning="medium"
    ;;
  low|medium|high|xhigh)
    ;;
  *)
    die "invalid reasoning level: $reasoning"
    ;;
esac

case "$model" in
  gpt-5.6-sol*)
    case "$reasoning" in
      high|xhigh)
        printf 'benny run: gpt-5.6-sol is capped at medium reasoning; clamping %s to medium\n' "$reasoning" >&2
        reasoning="medium"
        ;;
    esac
    ;;
esac

[[ -n "$repo" ]] || die "missing --repo"
[[ -d "$repo" ]] || die "repository does not exist: $repo"
repo="$(cd "$repo" && pwd)"

[[ -n "$config" ]] || die "missing --config"
config_abs="$(abs_path "$config")"
[[ -f "$config_abs" ]] || die "configuration file does not exist: $config_abs"

[[ -n "$source_channel" ]] || die "missing --source-channel"
[[ -n "$message_ts" ]] || die "missing --message-ts"
if [[ -z "$thread_ts" ]]; then
  thread_ts="$message_ts"
fi

case "$workflow" in
  triage)
    template="$pack_dir/templates/triage-automation-prompt.md"
    operational="$pack_dir/skills/triage-issue-reports/SKILL.md"
    slug="benny-triage"
    ;;
  reproduce)
    template="$pack_dir/templates/reproduce-automation-prompt.md"
    operational="$pack_dir/skills/reproduce-and-fix-issues/SKILL.md"
    slug="benny-reproduce"
    ;;
esac

[[ -f "$template" ]] || die "missing prompt template: $template"
[[ -f "$operational" ]] || die "missing operational file: $operational"

mkdir -p "$repo/.pstack/benny"
stamp="$(date +%Y%m%d-%H%M%S)"
if [[ -z "$output" ]]; then
  output="$repo/.pstack/benny/${stamp}-${slug}.md"
fi
if [[ -z "$log_file" ]]; then
  log_file="${output%.*}.jsonl"
fi
if [[ -z "$pid_file" ]]; then
  pid_file="${output%.*}.pid"
fi
if [[ -z "$prompt_out" ]]; then
  prompt_out="$repo/.pstack/benny/${stamp}-${slug}.prompt.md"
fi

mkdir -p "$(dirname "$output")" "$(dirname "$log_file")" "$(dirname "$pid_file")" "$(dirname "$prompt_out")"

template_text="$(cat "$template")"
trigger_json="$(printf '{"source_channel_id":"%s","message_ts":"%s","thread_ts":"%s"}' \
  "$(json_escape "$source_channel")" "$(json_escape "$message_ts")" "$(json_escape "$thread_ts")")"

rendered="$(replace_all "$template_text" "{{BENNY_CONFIG_PATH}}" "$config_abs")"
rendered="$(replace_all "$rendered" "{{SLACK_CHANNEL_ID}}" "$source_channel")"
rendered="$(replace_all "$rendered" "{{SLACK_MESSAGE_TS}}" "$message_ts")"
rendered="$(replace_all "$rendered" "{{SLACK_THREAD_TS_OR_EMPTY}}" "$thread_ts")"

prompt="$(cat <<EOF
You are running Benny through the uni-pstack portable runner.

Host contract:
- This is not Cursor /automate. Do not use Cursor automation editor behavior.
- Repository root: $repo
- Benny pack source: $pack_dir
- Operational file to read and follow: $operational
- Configuration file to read: $config_abs
- Trigger JSON: $trigger_json
- Resolve relative configuration paths from the repository root unless the value is absolute.
- Preserve immutable source coordinates from the trigger for every Slack read or write.
- The coordinator is the only external writer. Delegated workers must not receive Slack credentials or use Slack write actions.
- In Codex, use native Codex subagents when available. In Claude Code, this script already delegates to Codex CLI; do not spawn Claude workers for pstack work.
- Codex model policy: gpt-5.6-sol with task-aware reasoning, capped at medium. Use low for routine workers and explorers, medium for judgment, synthesis, and high-risk work. Never request high or xhigh on gpt-5.6-sol. This Benny coordinator uses medium unless the command line overrides it.
- Codex can be silent for more than 10 minutes. Use output files and logs rather than treating silence as failure.

Read the operational file before acting. Then run this workflow:

$rendered
EOF
)"

printf '%s\n' "$prompt" >"$prompt_out"

if [[ "$dry_run" -eq 1 ]]; then
  printf '%s\n' "$prompt"
  printf '\nRendered prompt: %s\n' "$prompt_out" >&2
  exit 0
fi

if ! command -v codex >/dev/null 2>&1; then
  die "codex CLI not found on PATH"
fi

cmd=(
  codex exec
  --cd "$repo"
  --model "$model"
  -c "model_reasoning_effort=\"$reasoning\""
  -c "service_tier=\"$service_tier\""
  --output-last-message "$output"
)

if [[ -n "$sandbox" ]]; then
  cmd+=(--sandbox "$sandbox")
fi

if [[ "$json" -eq 1 ]]; then
  cmd+=(--json)
fi

printf 'Starting %s with model=%s reasoning=%s service_tier=%s\n' "$slug" "$model" "$reasoning" "$service_tier" >&2
printf 'Prompt: %s\nOutput: %s\n' "$prompt_out" "$output" >&2

if [[ "$background" -eq 1 ]]; then
  printf 'Log: %s\nPID file: %s\n' "$log_file" "$pid_file" >&2
  nohup "${cmd[@]}" "$prompt" >"$log_file" 2>&1 &
  child_pid=$!
  printf '%s\n' "$child_pid" >"$pid_file"
  printf '%s started in background with pid %s\n' "$slug" "$child_pid" >&2
  exit 0
fi

"${cmd[@]}" "$prompt"
printf '\nBenny final message: %s\n' "$output" >&2
