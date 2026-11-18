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
if [ ! -d "$SRC/skills" ]; then
  SRC="$(mktemp -d)"
  trap 'rm -rf "$SRC"' EXIT
  git clone --depth 1 -q "$REPO" "$SRC"
fi

for t in "${TARGETS[@]}"; do
  mkdir -p "$t"
  for s in "$SRC"/skills/*/; do
    name="$(basename "$s")"
    rm -rf "${t:?}/$name"
    cp -r "$s" "$t/$name"
  done
  echo "installed $(ls "$SRC/skills" | wc -l | tr -d ' ') skills -> $t"
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

echo "done."
