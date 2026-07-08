#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/update-from-upstream.sh [options]

Fetch Cursor's upstream pstack plugin into .external/cursor-plugins, then refresh
source-managed upstream material in this repo. Native uni-pstack files such as
the Benny runner are preserved.

Options:
  --ref REF               Upstream ref to fetch. Default: main.
  --upstream-dir DIR      Existing cursor/plugins checkout. Default: .external/cursor-plugins.
  --dry-run               Show what would change without copying.
  --skip-validate         Do not run scripts/validate.sh after copying.
  -h, --help              Show this help.

Updated automatically:
  automations/benny/FOR_AGENTS.md
  automations/benny/templates/
  automations/benny/skills/
  agents/poteto-agent.md
  .cursor-plugin/plugin.json

The ported skills/ tree is intentionally not overwritten automatically because
each upstream skill needs the uni-pstack runtime adapter. The validation step
reports parity drift after fetch.
USAGE
}

die() {
  printf 'update-from-upstream: %s\n' "$*" >&2
  exit 1
}

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ref="main"
upstream_dir="$repo_dir/.external/cursor-plugins"
dry_run=0
skip_validate=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ref)
      ref="${2:?missing ref}"
      shift 2
      ;;
    --upstream-dir)
      upstream_dir="${2:?missing upstream directory}"
      shift 2
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    --skip-validate)
      skip_validate=1
      shift
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

upstream_dir_abs="$upstream_dir"
if [[ "$upstream_dir_abs" != /* ]]; then
  upstream_dir_abs="$repo_dir/$upstream_dir_abs"
fi

fetch_upstream() {
  if [[ ! -d "$upstream_dir_abs/.git" ]]; then
    mkdir -p "$(dirname "$upstream_dir_abs")"
    git clone --filter=blob:none --sparse https://github.com/cursor/plugins.git "$upstream_dir_abs"
    git -C "$upstream_dir_abs" sparse-checkout set pstack
  fi

  git -C "$upstream_dir_abs" remote set-url origin https://github.com/cursor/plugins.git
  git -C "$upstream_dir_abs" fetch --depth=1 origin "$ref"
  git -C "$upstream_dir_abs" checkout --detach FETCH_HEAD >/dev/null
}

sync_path() {
  local rel="$1"
  local src="$upstream_dir_abs/pstack/$rel"
  local dest="$repo_dir/$rel"

  [[ -e "$src" ]] || die "missing upstream path: pstack/$rel"

  if [[ "$dry_run" -eq 1 ]]; then
    printf 'would sync %s -> %s\n' "$src" "$dest"
    return 0
  fi

  mkdir -p "$(dirname "$dest")"
  if [[ -d "$src" ]]; then
    mkdir -p "$dest"
    rsync -a --delete "$src"/ "$dest"/
  else
    cp "$src" "$dest"
  fi
}

fetch_upstream

upstream_sha="$(git -C "$upstream_dir_abs" rev-parse HEAD)"
printf 'Upstream cursor/plugins pstack: %s\n' "$upstream_sha"

sync_path "automations/benny/FOR_AGENTS.md"
sync_path "automations/benny/templates"
sync_path "automations/benny/skills"
sync_path "agents/poteto-agent.md"
sync_path ".cursor-plugin/plugin.json"

if [[ "$dry_run" -eq 0 ]]; then
  printf '%s\n' "$upstream_sha" >"$repo_dir/automations/benny/.upstream-revision"
fi

if [[ "$skip_validate" -eq 0 && "$dry_run" -eq 0 ]]; then
  "$repo_dir/scripts/validate.sh"
fi

printf 'Update complete. Review git diff before committing.\n'
