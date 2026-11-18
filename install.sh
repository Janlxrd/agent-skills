#!/usr/bin/env bash
# Install all skills in this repo into ~/.agents/skills and ~/.claude/skills.
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Janlxrd/agent-skills/main/install.sh | bash
#   or: git clone https://github.com/Janlxrd/agent-skills && ./agent-skills/install.sh
set -euo pipefail

REPO="https://github.com/Janlxrd/agent-skills"
TARGETS=("$HOME/.agents/skills" "$HOME/.claude/skills")

# Use the local checkout if run from one, else clone to a temp dir.
SRC="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
if [ ! -d "$SRC/plugins/agent-skills/skills" ]; then
  SRC="$(mktemp -d)"
  trap 'rm -rf "$SRC"' EXIT
  git clone --depth 1 -q "$REPO" "$SRC"
fi

for t in "${TARGETS[@]}"; do
  mkdir -p "$t"
  for s in "$SRC"/plugins/agent-skills/skills/*/; do
    name="$(basename "$s")"
    rm -rf "${t:?}/$name"
    cp -r "$s" "$t/$name"
  done
  echo "installed $(ls "$SRC/plugins/agent-skills/skills" | wc -l | tr -d ' ') skills -> $t"
done

# anti-ui-slop is only published at uizze.com (not on GitHub), so pull it via the skills CLI.
if command -v npx >/dev/null; then
  npx -y skills add https://uizze.com --skill anti-ui-slop -g -y || echo "warn: anti-ui-slop install failed"
else
  echo "skip: anti-ui-slop (needs npx)"
fi

# unslop as a Claude Code plugin too (skill copy above works either way).
if command -v claude >/dev/null; then
  claude plugin marketplace add heydamir/unslop >/dev/null 2>&1 || true
  claude plugin install unslop@heydamir || echo "warn: unslop plugin install failed"
fi

# token-saving-mods: Claude Code plugin pack, Mac build (no Linux build yet).
# Copied to a fixed folder because a local marketplace points at its path.
MODS=(input-router effort-optimizer model-router cache-clock handoff research-router efficient-browser-use mods savings-proof)
if [ "$(uname)" = "Darwin" ] && command -v claude >/dev/null; then
  dest="$HOME/.claude/token-saving-mods"
  rm -rf "$dest"; cp -r "$SRC/mods/mac/token-saving-mods" "$dest"
  claude plugin marketplace add "$dest" >/dev/null 2>&1 || claude plugin marketplace update token-saving-mods >/dev/null 2>&1 || true
  for m in "${MODS[@]}"; do
    claude plugin install "$m@token-saving-mods" || echo "warn: $m install failed"
  done
  echo "installed token-saving-mods -> $dest (run /reload-plugins in open Claude Code chats)"
else
  echo "skip: token-saving-mods (needs macOS and claude on PATH)"
fi

echo "done."
