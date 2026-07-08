#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  install.sh [targets] [options]

Targets:
  --codex                 Install to Codex user skills.
  --claude                Install to Claude Code user skills.
  --all                   Install to both Codex and Claude Code.

Options:
  --codex-dir DIR         Override Codex skill directory.
                          Default: ${CODEX_HOME:-$HOME/.codex}/skills/pstack
  --claude-dir DIR        Override Claude Code skill directory.
                          Default: $HOME/.claude/skills/pstack
  --force                 Replace an existing install without prompting.
  --yes                   Non-interactive. If no target is supplied, installs both.
  --dry-run               Print what would happen without writing files.
  -h, --help              Show this help.

Human mode:
  With no target flags in an interactive terminal, the installer asks which
  targets to install. Press Enter to accept the default: Codex and Claude Code.

Examples:
  pstack/scripts/install.sh
  pstack/scripts/install.sh --all --force
  pstack/scripts/install.sh --codex
  pstack/scripts/install.sh --claude --claude-dir .claude/skills/pstack
USAGE
}

install_codex=0
install_claude=0
target_supplied=0
force=0
assume_yes=0
dry_run=0

codex_dir="${CODEX_HOME:-$HOME/.codex}/skills/pstack"
claude_dir="$HOME/.claude/skills/pstack"

die() {
  echo "install.sh: $*" >&2
  exit 1
}

is_interactive() {
  [[ -t 0 && -t 1 && "$assume_yes" -eq 0 ]]
}

abs_path() {
  local input="$1"
  local parent
  local base
  parent="$(dirname "$input")"
  base="$(basename "$input")"
  if [[ -d "$parent" ]]; then
    parent="$(cd "$parent" && pwd)"
  elif [[ "$parent" = /* ]]; then
    parent="$parent"
  else
    parent="$(pwd)/$parent"
  fi
  printf '%s/%s\n' "$parent" "$base"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --codex)
      install_codex=1
      target_supplied=1
      shift
      ;;
    --claude)
      install_claude=1
      target_supplied=1
      shift
      ;;
    --all)
      install_codex=1
      install_claude=1
      target_supplied=1
      shift
      ;;
    --codex-dir)
      codex_dir="${2:?missing Codex directory}"
      shift 2
      ;;
    --claude-dir)
      claude_dir="${2:?missing Claude Code directory}"
      shift 2
      ;;
    --force)
      force=1
      shift
      ;;
    --yes|-y)
      assume_yes=1
      shift
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skill_dir="$(cd "$script_dir/.." && pwd)"

prompt_targets() {
  local answer
  echo "Install pstack skill."
  echo
  echo "Targets:"
  echo "  1. Codex       -> $codex_dir"
  echo "  2. Claude Code -> $claude_dir"
  echo
  printf 'Install targets [both/codex/claude/none] (both): '
  IFS= read -r answer
  answer="${answer:-both}"
  case "$(printf '%s' "$answer" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')" in
    both|all|1,2|2,1|"")
      install_codex=1
      install_claude=1
      ;;
    codex|1)
      install_codex=1
      install_claude=0
      ;;
    claude|claudecode|2)
      install_codex=0
      install_claude=1
      ;;
    none|no|n|cancel)
      install_codex=0
      install_claude=0
      ;;
    *)
      die "unknown target selection: $answer"
      ;;
  esac
}

if [[ "$target_supplied" -eq 0 ]]; then
  if is_interactive; then
    prompt_targets
  else
    install_codex=1
    install_claude=1
  fi
fi

if [[ "$install_codex" -eq 0 && "$install_claude" -eq 0 ]]; then
  echo "No install targets selected."
  exit 0
fi

confirm_replace() {
  local dest="$1"
  local answer
  if [[ "$force" -eq 1 || "$assume_yes" -eq 1 ]]; then
    return 0
  fi
  if ! is_interactive; then
    return 1
  fi
  printf 'Replace existing install at %s? [y/N]: ' "$dest"
  IFS= read -r answer
  case "$(printf '%s' "$answer" | tr '[:upper:]' '[:lower:]')" in
    y|yes)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

copy_skill() {
  local label="$1"
  local dest="$2"
  local abs_dest
  local abs_src
  abs_dest="$(abs_path "$dest")"
  abs_src="$(cd "$skill_dir" && pwd)"

  if [[ "$abs_dest" == "$abs_src" ]]; then
    echo "$label already points at source: $abs_dest"
    return 0
  fi

  if [[ "$dry_run" -eq 1 ]]; then
    echo "would install $label: $abs_src -> $abs_dest"
    return 0
  fi

  mkdir -p "$(dirname "$abs_dest")"

  if [[ -e "$abs_dest" ]]; then
    if ! confirm_replace "$abs_dest"; then
      die "$label destination exists: $abs_dest (use --force to replace)"
    fi
    rm -rf "$abs_dest"
  fi

  cp -R "$abs_src" "$abs_dest"
  echo "installed $label: $abs_dest"
}

echo "Source: $skill_dir"
if [[ "$install_codex" -eq 1 ]]; then
  copy_skill "Codex" "$codex_dir"
fi

if [[ "$install_claude" -eq 1 ]]; then
  copy_skill "Claude Code" "$claude_dir"
fi

echo
echo "Next:"
if [[ "$install_codex" -eq 1 ]]; then
  echo "  Codex: start a new session, then use: Use \$pstack to ..."
fi
if [[ "$install_claude" -eq 1 ]]; then
  echo "  Claude Code: restart or reload, then use: /pstack ..."
fi
