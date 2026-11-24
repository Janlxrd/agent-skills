#!/usr/bin/env bash
# Install my agent skills, the Karpathy coding rules and graphify, each from its own source.
#
#   curl -fsSL https://raw.githubusercontent.com/Janlxrd/agent-skills/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/Janlxrd/agent-skills/main/install.sh | bash -s -- --no-graphify
#
# Run with --help for all options.
set -euo pipefail

# "source skill". Installed with the skills CLI (npx skills), which copies each
# skill into every agent it finds (Claude Code, Cursor, Codex, Gemini CLI, ...).
SKILLS=(
  "mattpocock/skills grill-me"
  "mattpocock/skills grilling"
  "vercel-labs/agent-browser agent-browser"
  "vercel-labs/skills find-skills"
  "vercel-labs/agent-skills web-design-guidelines"
  "anthropics/skills canvas-design"
  "coreyhaines31/marketingskills seo-audit"
  "heydamir/unslop unslop"
  "https://uizze.com anti-ui-slop"
  "Leonxlnx/taste-skill design-taste-frontend"
  "blader/humanizer humanizer"
)

usage() {
  cat <<'EOF'
Usage: install.sh [options]

Installs, each from its own source:
  - the skills, with npx skills (needs Node.js)
  - the Karpathy coding rules plugin for Claude Code (needs claude)
  - graphify, with uv or pipx (needs one of them)
  - headroom, with uv (needs uv). Start Claude with: headroom wrap claude

Options
  --only a,b,c    Just these skills. See --list.
  --no-rules      Skip the Karpathy rules plugin.
  --no-graphify   Skip graphify.
  --no-headroom   Skip headroom.
  --no-red        Skip claude-red (79 offensive-security skills).
  --list          List the skills and exit.
  -h, --help      Show this help.
EOF
}

ONLY="" NO_RULES=0 NO_GRAPHIFY=0 NO_HEADROOM=0 NO_RED=0
while [ $# -gt 0 ]; do
  case "$1" in
    --only) shift; ONLY="${1:-}" ;;
    --only=*) ONLY="${1#*=}" ;;
    --no-rules) NO_RULES=1 ;;
    --no-graphify) NO_GRAPHIFY=1 ;;
    --no-headroom) NO_HEADROOM=1 ;;
    --no-red) NO_RED=1 ;;
    --list) for s in "${SKILLS[@]}"; do echo "${s#* }"; done; exit 0 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

has() { command -v "$1" >/dev/null 2>&1; }

# Pick the skills.
WANT=()
if [ -n "$ONLY" ]; then
  IFS=',' read -r -a req <<< "$ONLY"
  for r in "${req[@]}"; do
    r="$(echo "$r" | tr -d ' ')"; [ -z "$r" ] && continue
    found=""
    for s in "${SKILLS[@]}"; do [ "${s#* }" = "$r" ] && found="$s"; done
    [ -n "$found" ] || { echo "unknown skill: $r (see --list)" >&2; exit 1; }
    WANT+=("$found")
  done
else
  WANT=("${SKILLS[@]}")
fi

# Install missing tools (Node.js, uv) so everything works the first time.
export PATH="$HOME/.local/bin:$PATH"
if ! has npx; then
  if has brew; then echo "installing Node.js (brew)..."; brew install node >/dev/null 2>&1 || true; fi
  has npx || echo "warn: Node.js not found, so the skills can't install. Get it from https://nodejs.org and run this again."
fi
if [ -z "$ONLY" ] && { [ "$NO_GRAPHIFY" = 0 ] || [ "$NO_HEADROOM" = 0 ]; } && ! has uv; then
  echo "installing uv (astral.sh)..."
  curl -LsSf https://astral.sh/uv/install.sh | sh >/dev/null 2>&1 || true
  has uv || echo "warn: uv install failed, so graphify and headroom will be skipped"
fi

# Older versions of this repo shipped its own copy of the skills as a plugin and
# as copied folders. Remove those so nothing loads twice. Only our skill names
# are touched; your own skills stay.
if has claude; then
  for p in agent-skills@janlxrd global-rules@janlxrd unslop@heydamir; do
    if claude plugin list 2>/dev/null | grep -q "$p"; then
      claude plugin uninstall "$p" >/dev/null 2>&1 && echo "removed old plugin $p"
    fi
  done
  claude plugin marketplace remove janlxrd >/dev/null 2>&1 && echo "removed old marketplace janlxrd" || true
fi
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
for dir in "$HOME/.claude/skills" "$HOME/.cursor/skills" "$HOME/.gemini/skills" "$HOME/.copilot/skills" \
           "$HOME/.codeium/windsurf/skills" "$CFG/opencode/skills"; do
  for s in "${WANT[@]}" "x karpathy-guidelines"; do
    name="${s#* }"
    # Real folders only: links made by npx skills are left for it to manage.
    if [ -d "$dir/$name" ] && [ ! -L "$dir/$name" ]; then
      rm -rf "${dir:?}/$name"; echo "removed old copy $dir/$name"
    fi
  done
done
md="$HOME/.claude/CLAUDE.md"
if [ -f "$md" ] && grep -qF "<!-- agent-skills:start -->" "$md"; then
  cp "$md" "$md.bak"
  awk '$0=="<!-- agent-skills:start -->"{skip=1;next} $0=="<!-- agent-skills:end -->"{skip=0;next} !skip' "$md.bak" > "$md"
  echo "removed old agent-skills block from $md (backup: $md.bak)"
fi

# Skills.
if has npx; then
  for s in "${WANT[@]}"; do
    src="${s% *}" name="${s#* }"
    if npx -y skills@latest add "$src" --skill "$name" -g -y >/dev/null 2>&1; then
      echo "installed $name from $src"
    else
      echo "warn: $name failed. Try: npx skills add $src --skill $name -g"
    fi
  done
else
  echo "skip: skills (needs Node.js for npx: https://nodejs.org)"
fi

# claude-red: 79 offensive-security skills (SnailSploit/claude-red). All of them
# are named offensive-*, which is how the uninstaller finds them again.
if [ "$NO_RED" = 0 ] && [ -z "$ONLY" ]; then
  if has npx; then
    if npx -y skills@latest add SnailSploit/claude-red --skill '*' -g -y >/dev/null 2>&1; then
      echo "installed claude-red (79 offensive-security skills)"
    else
      echo "warn: claude-red failed. Try: npx skills add SnailSploit/claude-red --skill '*' -g"
    fi
  fi
fi

# Karpathy coding rules: their own Claude Code plugin.
if [ "$NO_RULES" = 0 ] && [ -z "$ONLY" ]; then
  if has claude; then
    claude plugin marketplace add multica-ai/andrej-karpathy-skills >/dev/null 2>&1 || claude plugin marketplace update karpathy-skills >/dev/null 2>&1 || true
    if claude plugin install andrej-karpathy-skills@karpathy-skills >/dev/null 2>&1; then
      echo "installed Karpathy rules plugin from multica-ai/andrej-karpathy-skills"
    else
      echo "warn: Karpathy rules plugin install failed"
    fi
  else
    echo "skip: Karpathy rules plugin (needs claude on PATH)"
  fi
fi

# graphify: Python CLI, then its own installer adds the skill to Claude Code.
# Run from a temp folder so it can't touch files in the folder you're in.
if [ "$NO_GRAPHIFY" = 0 ] && [ -z "$ONLY" ]; then
  ok=0
  if has uv; then uv tool install --upgrade graphifyy >/dev/null 2>&1 && ok=1
  elif has pipx; then pipx install graphifyy >/dev/null 2>&1 || pipx upgrade graphifyy >/dev/null 2>&1; ok=1
  fi
  if [ "$ok" = 1 ] && has graphify; then
    (cd "$(mktemp -d)" && graphify install >/dev/null) && echo "installed graphify (type /graphify . in Claude Code)"
  elif [ "$ok" = 1 ]; then
    echo "warn: graphify installed but isn't on PATH yet. Open a new terminal and run: graphify install"
  else
    echo "skip: graphify (needs uv or pipx: https://docs.astral.sh/uv/)"
  fi
fi

# headroom: cuts the tokens Claude Code sends by squeezing context through a local proxy.
# Only the CLI is installed; nothing changes until you start Claude with headroom wrap claude.
if [ "$NO_HEADROOM" = 0 ] && [ -z "$ONLY" ]; then
  if has uv; then
    if uv tool install --upgrade --python 3.13 "headroom-ai[all]" >/dev/null 2>&1; then
      echo "installed headroom (start Claude with: headroom wrap claude)"
    else
      echo "warn: headroom install failed. Try: uv tool install --python 3.13 \"headroom-ai[all]\""
    fi
  else
    echo "skip: headroom (needs uv: https://docs.astral.sh/uv/)"
  fi
fi

# Put uv's tools (graphify, headroom) on PATH for new terminals.
has uv && uv tool update-shell >/dev/null 2>&1 || true

echo "done. Open a new terminal, and run /reload-plugins in open Claude Code chats."
