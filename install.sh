#!/usr/bin/env bash
# Install the agent-skills plugin (Claude Code), the skill files (other tools) and the mods.
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

# Skill files always go to ~/.agents/skills (Codex, Cline, Warp, Zed, Kimi, ...).
# Claude Code gets them from the agent-skills plugin instead, unless --skills-only/--only
# is used or claude isn't installed, in which case they're copied to ~/.claude/skills.
BASE_TARGETS=("$HOME/.agents/skills")
CLAUDE_SKILLS="$HOME/.claude/skills"
# Skills that used to be in this repo; old copies are removed.
RETIRED=(karpathy-guidelines)
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

By default:
  - Claude Code gets the agent-skills plugin (all skills + always-on coding
    and writing rules), installed from the Janlxrd/agent-skills marketplace.
  - Other tools get the skill files: ~/.agents/skills, plus Cursor, Gemini CLI,
    GitHub Copilot, Windsurf and OpenCode if they're installed.
  - The token-saving mods (macOS only from this script).

Options
  --skills-only      Only skill files, everywhere (incl. ~/.claude/skills).
                     No plugin, no rules, no mods.
  --only a,b,c       Like --skills-only, but just these skills. See --list.
  --no-mods          Skip the token-saving mods.
  --all-tools        Copy skill files into those tools even if they aren't found.
  --no-tools         Skill files only into ~/.agents/skills.
  --list             List the skills and exit.
  -h, --help         Show this help.
EOF
}

FILES_ONLY=0 SKIP_MODS=0 ONLY="" ONLY_SET=0 TOOLS_MODE=detect LIST=0
while [ $# -gt 0 ]; do
  case "$1" in
    --skills-only) FILES_ONLY=1; SKIP_MODS=1 ;;
    --no-mods) SKIP_MODS=1 ;;
    --only) shift; ONLY="${1:-}"; ONLY_SET=1; FILES_ONLY=1; SKIP_MODS=1 ;;
    --only=*) ONLY="${1#*=}"; ONLY_SET=1; FILES_ONLY=1; SKIP_MODS=1 ;;
    --all-tools) TOOLS_MODE=all ;;
    --no-tools) TOOLS_MODE=none ;;
    --list) LIST=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

HAS_CLAUDE=0; command -v claude >/dev/null && HAS_CLAUDE=1
USE_PLUGIN=0; [ "$FILES_ONLY" = 0 ] && [ "$HAS_CLAUDE" = 1 ] && USE_PLUGIN=1

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
[ "$USE_PLUGIN" = 1 ] || TARGETS+=("$CLAUDE_SKILLS")
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
  for r in "${RETIRED[@]}"; do rm -rf "${t:?}/$r"; done
  count=0
  for name in "${WANT[@]}"; do
    [ -d "$SKILLS_DIR/$name" ] || continue
    rm -rf "${t:?}/$name"
    cp -r "$SKILLS_DIR/$name" "$t/$name"
    count=$((count + 1))
  done
  echo "copied $count skills -> $t"
done

# anti-ui-slop is only published at uizze.com, so pull it via the skills CLI.
if want anti-ui-slop; then
  if command -v npx >/dev/null; then
    npx -y skills add https://uizze.com --skill anti-ui-slop -g -y || echo "warn: anti-ui-slop install failed"
  else
    echo "skip: anti-ui-slop (needs npx)"
  fi
fi

# agent-skills plugin for Claude Code: the skills plus always-on rules.
if [ "$USE_PLUGIN" = 1 ]; then
  claude plugin marketplace add Janlxrd/agent-skills >/dev/null 2>&1 || claude plugin marketplace update janlxrd >/dev/null 2>&1 || true
  claude plugin install agent-skills@janlxrd || echo "warn: agent-skills plugin install failed"
  claude plugin update agent-skills@janlxrd >/dev/null 2>&1 || true

  # Clean up what older versions of this script installed, so nothing loads twice.
  # Only folders/plugins this script put there are touched.
  for name in "${ALL[@]}" "${RETIRED[@]}"; do
    [ "$name" = anti-ui-slop ] && continue
    if [ -d "$CLAUDE_SKILLS/$name" ]; then rm -rf "${CLAUDE_SKILLS:?}/$name"; echo "removed old copy $CLAUDE_SKILLS/$name (now in the plugin)"; fi
  done
  for p in global-rules@janlxrd unslop@heydamir; do
    if claude plugin list 2>/dev/null | grep -q "$p"; then
      claude plugin uninstall "$p" >/dev/null 2>&1 && echo "removed old plugin $p (now in agent-skills)"
    fi
  done
elif [ "$FILES_ONLY" = 0 ]; then
  echo "skip: agent-skills plugin (needs claude on PATH); skill files copied to $CLAUDE_SKILLS instead"
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

# An older version of this script wrote the rules into ~/.claude/CLAUDE.md.
# Remove only that marked block so the rules aren't loaded twice. Nothing else is touched.
md="$HOME/.claude/CLAUDE.md"
if [ -f "$md" ] && grep -qF "<!-- agent-skills:start -->" "$md"; then
  cp "$md" "$md.bak"
  awk '$0=="<!-- agent-skills:start -->"{skip=1;next} $0=="<!-- agent-skills:end -->"{skip=0;next} !skip' "$md.bak" > "$md"
  echo "removed old agent-skills block from $md (backup: $md.bak)"
fi

echo "done."
