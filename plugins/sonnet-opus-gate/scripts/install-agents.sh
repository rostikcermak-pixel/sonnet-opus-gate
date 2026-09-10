#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-only
# Install the sonnet-opus-gate reviewer subagent into a Claude Code agents directory.

set -eu

usage() {
  cat <<'USAGE'
Usage: install-agents.sh [--target-dir PATH] [--check] [--force] [--help]

Install the sonnet-opus-gate reviewer agent template into the target directory.
An existing destination that differs from the template is never overwritten unless
--force is given.

Without --target-dir, the target is "$CLAUDE_CONFIG_DIR/agents" when CLAUDE_CONFIG_DIR
is set, otherwise "$HOME/.claude/agents".

Options:
  --target-dir PATH  Explicit destination directory (absolute or relative).
  --check            Verify the installed agent matches the template and is pinned to
                     Opus. Creates, replaces, and removes nothing.
  --force            Replace a destination that differs from the template.
  --help             Show this help text.
USAGE
}

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
template="$script_dir/../agents/reviewer.md"
agent_name=reviewer.md

target_dir=""
check_only=0
force=0

while [ $# -gt 0 ]; do
  case $1 in
    --target-dir)
      [ $# -ge 2 ] || fail "--target-dir requires a path"
      target_dir=$2
      shift 2
      ;;
    --target-dir=*)
      target_dir=${1#--target-dir=}
      shift
      ;;
    --check)
      check_only=1
      shift
      ;;
    --force)
      force=1
      shift
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      fail "unknown argument: $1"
      ;;
  esac
done

[ -f "$template" ] || fail "template not found: $template"

if [ -z "$target_dir" ]; then
  if [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then
    target_dir="$CLAUDE_CONFIG_DIR/agents"
  else
    [ -n "${HOME:-}" ] || fail "neither --target-dir, CLAUDE_CONFIG_DIR, nor HOME is set"
    target_dir="$HOME/.claude/agents"
  fi
fi

destination="$target_dir/$agent_name"

grep -q '^model: opus[[:space:]]*$' "$template" ||
  fail "template is not pinned to Opus: $template"

if [ "$check_only" -eq 1 ]; then
  [ -e "$destination" ] || fail "not installed: $destination"
  [ -f "$destination" ] && [ ! -L "$destination" ] ||
    fail "destination is not a regular file: $destination"
  cmp -s "$template" "$destination" ||
    fail "destination differs from template: $destination"
  grep -q '^model: opus[[:space:]]*$' "$destination" ||
    fail "installed agent is not pinned to Opus: $destination"
  printf 'ok: %s matches the template and is pinned to Opus\n' "$destination"
  exit 0
fi

if [ -e "$destination" ] || [ -L "$destination" ]; then
  if [ -L "$destination" ] || [ ! -f "$destination" ]; then
    fail "refusing to replace a symlink or non-regular file: $destination"
  fi
  if cmp -s "$template" "$destination"; then
    printf 'unchanged: %s\n' "$destination"
    exit 0
  fi
  if [ "$force" -eq 0 ]; then
    fail "destination differs from the template; rerun with --force to replace: $destination"
  fi
fi

mkdir -p "$target_dir"
cp "$template" "$destination"
printf 'installed: %s\n' "$destination"
