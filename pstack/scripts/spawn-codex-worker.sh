#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  spawn-codex-worker.sh [--role worker|explorer|judge] [--cwd DIR] [--output FILE]
                        [--model MODEL] [--reasoning low|medium|high|xhigh]
                        [--service-tier TIER] [--sandbox MODE] [--json]
                        [--background] [--log FILE] [--pid-file FILE] -- "prompt"

Reads the prompt from arguments after --, or from stdin when no prompt is provided.
Defaults are tuned for pstack Claude-to-Codex delegation:
  model:        PSTACK_CODEX_MODEL or gpt-5.5
  reasoning:    PSTACK_CODEX_REASONING or high
  service tier: PSTACK_CODEX_SERVICE_TIER or fast
USAGE
}

role="worker"
cwd="$PWD"
output=""
model="${PSTACK_CODEX_MODEL:-gpt-5.5}"
reasoning="${PSTACK_CODEX_REASONING:-high}"
service_tier="${PSTACK_CODEX_SERVICE_TIER:-fast}"
sandbox="${PSTACK_CODEX_SANDBOX:-}"
json=0
background=0
log_file=""
pid_file=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --role)
      role="${2:?missing role}"
      shift 2
      ;;
    --cwd)
      cwd="${2:?missing cwd}"
      shift 2
      ;;
    --output)
      output="${2:?missing output}"
      shift 2
      ;;
    --model)
      model="${2:?missing model}"
      shift 2
      ;;
    --reasoning)
      reasoning="${2:?missing reasoning}"
      shift 2
      ;;
    --service-tier)
      service_tier="${2:?missing service tier}"
      shift 2
      ;;
    --sandbox)
      sandbox="${2:?missing sandbox}"
      shift 2
      ;;
    --json)
      json=1
      shift
      ;;
    --background)
      background=1
      shift
      ;;
    --log)
      log_file="${2:?missing log file}"
      shift 2
      ;;
    --pid-file)
      pid_file="${2:?missing pid file}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    *)
      break
      ;;
  esac
done

if ! command -v codex >/dev/null 2>&1; then
  echo "codex CLI not found on PATH" >&2
  exit 127
fi

if [[ $# -gt 0 ]]; then
  prompt="$*"
else
  prompt="$(cat)"
fi

if [[ -z "${prompt//[[:space:]]/}" ]]; then
  echo "empty prompt" >&2
  usage >&2
  exit 2
fi

mkdir -p "$cwd/.pstack/workers"

if [[ -z "$output" ]]; then
  slug="$(printf '%s' "$role" | tr -cs '[:alnum:]_.-' '-')"
  stamp="$(date +%Y%m%d-%H%M%S)"
  output="$cwd/.pstack/workers/${stamp}-${slug}.md"
fi

mkdir -p "$(dirname "$output")"

if [[ -z "$log_file" ]]; then
  log_file="${output%.*}.jsonl"
fi

if [[ -z "$pid_file" ]]; then
  pid_file="${output%.*}.pid"
fi

mkdir -p "$(dirname "$log_file")" "$(dirname "$pid_file")"

wrapped_prompt="$(cat <<EOF
You are a pstack Codex ${role}.

Use rigorous engineering judgment. Keep the task bounded. If you edit code, do not revert edits made by others. Verify against the real artifact when possible.

Task:
${prompt}

Return:
- files changed or inspected,
- what you did or found,
- verification result,
- risks, blockers, or follow-up.
EOF
)"

cmd=(
  codex exec
  --cd "$cwd"
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

printf 'Starting Codex %s with model=%s reasoning=%s service_tier=%s\n' "$role" "$model" "$reasoning" "$service_tier" >&2
printf 'Output: %s\n' "$output" >&2
if [[ "$background" -eq 1 ]]; then
  printf 'Log: %s\n' "$log_file" >&2
  printf 'PID file: %s\n' "$pid_file" >&2
  nohup "${cmd[@]}" "$wrapped_prompt" >"$log_file" 2>&1 &
  child_pid=$!
  printf '%s\n' "$child_pid" >"$pid_file"
  printf 'Codex worker started in background with pid %s\n' "$child_pid" >&2
  exit 0
fi

"${cmd[@]}" "$wrapped_prompt"

printf '\nCodex worker final message: %s\n' "$output" >&2
