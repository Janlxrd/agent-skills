#!/usr/bin/env bash
# Install the skills (and optionally the Claude Code plugins and mods) from this repo.
#
#   curl -fsSL https://raw.githubusercontent.com/Janlxrd/agent-skills/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/Janlxrd/agent-skills/main/install.sh | bash -s -- --skills-only
#   ./install.sh --only grill-me,unslop
#
# Run with --help for all options.
set -euo pipefail

REPO="https://github.com/Janlxrd/agent-skills"
MODS=(input-router effort-optimizer model-router cache-clock handoff research-router efficient-browser-use mods savings-proof)
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"

# Always installed to: ~/.agents/skills (Codex, Cline, Warp, Zed, Kimi, ...) and ~/.claude/skills.
BASE_TARGETS=("$HOME/.agents/skills" "$HOME/.claude/skills")
# Extra tools: "name|folder that means it's installed|skills folder".
TOOLS=(
  "Cursor|$HOME/.cursor|$HOME/.cursor/skills"
  "Gemini CLI|$HOME/.gemini|$HOME/.gemini/skills"
  "GitHub Copilot|$HOME/.copilot|$HOME/.copilot/skills"
  "Windsurf|$HOME/.codeium/windsurf|$HOME/.codeium/windsurf/skills"
  "OpenCode|$CFG/opencode|$CFG/opencode/skills"
)

usage() {
  cat <<'EOF'
Usage: install.sh [options]

What to install (default: everything)
  --skills-only      Only the skills. No Claude Code plugins, no mods.
  --no-mods          Skip the token-saving mods.
  --no-plugins       Skip the unslop Claude Code plugin.
  --only a,b,c       Only these skills (implies --skills-only). See --list.

Where skills go (default: ~/.agents/skills, ~/.claude/skills, plus any of
Cursor, Gemini CLI, GitHub Copilot, Windsurf, OpenCode found on this machine)
  --all-tools        Also install into those tools even if they aren't found.
  --no-tools         Only ~/.agents/skills and ~/.claude/skills.

  --list             List the skills and exit.
  -h, --help         Show this help.
EOF
}

SKIP_MODS=0 SKIP_PLUGINS=0 ONLY="" ONLY_SET=0 TOOLS_MODE=detect LIST=0
while [ $# -gt 0 ]; do
  case "$1" in
    --skills-only) SKIP_MODS=1; SKIP_PLUGINS=1 ;;
    --no-mods) SKIP_MODS=1 ;;
    --no-plugins) SKIP_PLUGINS=1 ;;
    --only) shift; ONLY="${1:-}"; ONLY_SET=1; SKIP_MODS=1; SKIP_PLUGINS=1 ;;
    --only=*) ONLY="${1#*=}"; ONLY_SET=1; SKIP_MODS=1; SKIP_PLUGINS=1 ;;
    --all-tools) TOOLS_MODE=all ;;
    --no-tools) TOOLS_MODE=none ;;
    --list) LIST=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

# Use the local checkout if run from one, else clone to a temp dir.
SRC="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
if [ ! -d "$SRC/plugins/agent-skills/skills" ]; then
  SRC="$(mktemp -d)"
  trap 'rm -rf "$SRC"' EXIT
  git clone --depth 1 -q "$REPO" "$SRC"
fi
SKILLS_DIR="$SRC/plugins/agent-skills/skills"

ALL=()
for s in "$SKILLS_DIR"/*/; do ALL+=("$(basename "$s")"); done
ALL+=(anti-ui-slop)  # fetched from uizze.com, not stored in this repo

if [ "$LIST" = 1 ]; then printf '%s\n' "${ALL[@]}"; exit 0; fi

# Work out which skills to install.
WANT=()
if [ "$ONLY_SET" = 1 ]; then
  IFS=',' read -r -a req <<< "$ONLY"
  for r in "${req[@]}"; do
    r="$(echo "$r" | tr -d ' ')"; [ -z "$r" ] && continue
    if printf '%s\n' "${ALL[@]}" | grep -qx "$r"; then WANT+=("$r")
    else echo "unknown skill: $r (see --list)" >&2; exit 1; fi
  done
else
  WANT=("${ALL[@]}")
fi
[ ${#WANT[@]} -gt 0 ] || { echo "--only needs at least one skill name (see --list)" >&2; exit 1; }
want() { printf '%s\n' "${WANT[@]}" | grep -qx "$1"; }

# Work out where they go.
TARGETS=("${BASE_TARGETS[@]}")
for t in "${TOOLS[@]}"; do
  IFS='|' read -r name marker dir <<< "$t"
  if [ "$TOOLS_MODE" = all ] || { [ "$TOOLS_MODE" = detect ] && [ -d "$marker" ]; }; then
    TARGETS+=("$dir")
  fi
done

# Copy the bundled skills.
count=0
for t in "${TARGETS[@]}"; do
  mkdir -p "$t"
  count=0
  for name in "${WANT[@]}"; do
    [ -d "$SKILLS_DIR/$name" ] || continue
    rm -rf "${t:?}/$name"
    cp -r "$SKILLS_DIR/$name" "$t/$name"
    count=$((count + 1))
  done
  echo "installed $count skills -> $t"
done

# anti-ui-slop is only published at uizze.com, so pull it via the skills CLI.
if want anti-ui-slop; then
  if command -v npx >/dev/null; then
    npx -y skills add https://uizze.com --skill anti-ui-slop -g -y || echo "warn: anti-ui-slop install failed"
  else
    echo "skip: anti-ui-slop (needs npx)"
  fi
fi

# unslop as a Claude Code plugin too (the skill copy above works either way).
if [ "$SKIP_PLUGINS" = 0 ] && command -v claude >/dev/null; then
  claude plugin marketplace add heydamir/unslop >/dev/null 2>&1 || true
  claude plugin install unslop@heydamir || echo "warn: unslop plugin install failed"
fi

# token-saving-mods: Claude Code plugin pack, Mac build (no Linux build yet).
# Copied to a fixed folder because a local marketplace points at its path.
if [ "$SKIP_MODS" = 0 ]; then
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
fi

echo "done."
