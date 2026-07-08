#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  ./install.sh [targets] [options]

Targets:
  --codex                 Install the full suite to Codex user skills.
  --claude                Install the full suite to Claude Code user skills.
  --all                   Install to both Codex and Claude Code.

Options:
  --update                Update installed copies from this repo. Equivalent to
                          --all --force --yes when no target is supplied.
  --codex-dir DIR         Override Codex skills directory.
                          Default: ${CODEX_HOME:-$HOME/.codex}/skills
  --claude-dir DIR        Override Claude Code skills directory.
                          Default: $HOME/.claude/skills
  --force                 Replace existing installed skill folders without prompting.
  --yes                   Non-interactive. If no target is supplied, installs both.
  --dry-run               Print what would happen without writing files.
  -h, --help              Show this help.

Human mode:
  With no target flags in an interactive terminal, the installer asks which
  targets to install. Press Enter to accept the default: Codex and Claude Code.

Examples:
  ./install.sh
  ./install.sh --update
  ./install.sh --update --codex
  ./install.sh --all --force
  ./install.sh --codex
  ./install.sh --claude --claude-dir .claude/skills
USAGE
}

install_codex=0
install_claude=0
target_supplied=0
force=0
assume_yes=0
dry_run=0
update=0

codex_dir="${CODEX_HOME:-$HOME/.codex}/skills"
claude_dir="$HOME/.claude/skills"

die() {
  echo "install.sh: $*" >&2
  exit 1
}

is_interactive() {
  [[ -t 0 && -t 1 && "$assume_yes" -eq 0 ]]
}

abs_dir() {
  local input="$1"
  if [[ -d "$input" ]]; then
    (cd "$input" && pwd)
  elif [[ "$input" = /* ]]; then
    printf '%s\n' "$input"
  else
    printf '%s/%s\n' "$(pwd)" "$input"
  fi
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
      codex_dir="${2:?missing Codex skills directory}"
      shift 2
      ;;
    --claude-dir)
      claude_dir="${2:?missing Claude Code skills directory}"
      shift 2
      ;;
    --force)
      force=1
      shift
      ;;
    --update)
      update=1
      force=1
      assume_yes=1
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

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -f "$repo_dir/pstack/SKILL.md" ]]; then
  die "could not find pstack/SKILL.md next to install.sh"
fi

if [[ ! -d "$repo_dir/skills" ]]; then
  die "could not find skills/ next to install.sh"
fi

prompt_targets() {
  local answer
  echo "Install uni-pstack skill suite."
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
  if [[ "$update" -eq 1 ]]; then
    install_codex=1
    install_claude=1
  elif is_interactive; then
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

skill_sources() {
  local src
  printf '%s\n' "$repo_dir/pstack"
  for src in "$repo_dir"/skills/*; do
    [[ -f "$src/SKILL.md" ]] || continue
    printf '%s\n' "$src"
  done
}

copy_one_skill() {
  local label="$1"
  local root="$2"
  local src="$3"
  local name
  local abs_root
  local abs_src
  local dest
  name="$(basename "$src")"
  abs_root="$(abs_dir "$root")"
  abs_src="$(cd "$src" && pwd)"
  dest="$abs_root/$name"

  if [[ "$dest" == "$abs_src" ]]; then
    echo "$label $name already points at source: $dest"
    return 0
  fi

  if [[ "$dry_run" -eq 1 ]]; then
    echo "would install $label $name: $abs_src -> $dest"
    if [[ "$name" == "pstack" && -d "$repo_dir/automations/benny" ]]; then
      echo "would bundle $label benny automation runner: $repo_dir/automations/benny -> $dest/automations/benny"
    fi
    return 0
  fi

  mkdir -p "$abs_root"

  if [[ -e "$dest" ]]; then
    if ! confirm_replace "$dest"; then
      die "$label destination exists: $dest (use --force to replace)"
    fi
    rm -rf "$dest"
  fi

  cp -R "$abs_src" "$dest"
  if [[ "$name" == "pstack" && -d "$repo_dir/automations/benny" ]]; then
    mkdir -p "$dest/automations"
    rm -rf "$dest/automations/benny"
    cp -R "$repo_dir/automations/benny" "$dest/automations/benny"
  fi
  echo "installed $label $name: $dest"
}

copy_suite() {
  local label="$1"
  local root="$2"
  local src
  local count=0
  echo "Target $label: $(abs_dir "$root")"
  while IFS= read -r src; do
    copy_one_skill "$label" "$root" "$src"
    count=$((count + 1))
  done < <(skill_sources)
  echo "installed $count $label skill folders"
}

echo "Source: $repo_dir"
if [[ "$update" -eq 1 ]]; then
  echo "Mode: update installed copies"
fi
if [[ "$install_codex" -eq 1 ]]; then
  copy_suite "Codex" "$codex_dir"
fi

if [[ "$install_claude" -eq 1 ]]; then
  copy_suite "Claude Code" "$claude_dir"
fi

echo
echo "Next:"
if [[ "$install_codex" -eq 1 ]]; then
  echo "  Codex: start a new session, then use: Use \$pstack to ..."
fi
if [[ "$install_claude" -eq 1 ]]; then
  echo "  Claude Code: restart or reload, then use: /pstack ..."
fi
