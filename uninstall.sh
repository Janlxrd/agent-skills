#!/usr/bin/env bash
# Remove what install.sh installed. Nothing else is touched.
#
#   curl -fsSL https://raw.githubusercontent.com/Janlxrd/agent-skills/main/uninstall.sh | bash
set -uo pipefail

SKILLS=(grill-me grilling agent-browser find-skills web-design-guidelines canvas-design seo-audit unslop anti-ui-slop design-taste-frontend humanizer)
has() { command -v "$1" >/dev/null 2>&1; }
export PATH="$HOME/.local/bin:$PATH"   # where uv puts graphify and headroom

# Skills, from every agent npx skills put them in.
if has npx; then
  args=(); for s in "${SKILLS[@]}"; do args+=(--skill "$s"); done
  npx -y skills@latest remove -g -y "${args[@]}" >/dev/null 2>&1 && echo "removed skills: ${SKILLS[*]}"
  # claude-red: every installed skill named offensive-* .
  red="$(npx -y skills@latest list -g 2>/dev/null | grep -oE 'offensive-[a-z0-9-]+' | sort -u)"
  if [ -n "$red" ]; then
    rargs=(); for s in $red; do rargs+=(--skill "$s"); done
    npx -y skills@latest remove -g -y "${rargs[@]}" >/dev/null 2>&1 && echo "removed claude-red ($(echo "$red" | wc -l | tr -d ' ') skills)"
  fi
else
  echo "skip: skills (needs Node.js for npx)"
fi

# Karpathy rules plugin, plus the old plugins from this repo.
if has claude; then
  for p in andrej-karpathy-skills@karpathy-skills agent-skills@janlxrd global-rules@janlxrd; do
    if claude plugin list 2>/dev/null | grep -q "$p"; then
      claude plugin uninstall "$p" >/dev/null 2>&1 && echo "removed plugin $p"
    fi
  done
  for m in karpathy-skills janlxrd; do
    claude plugin marketplace remove "$m" >/dev/null 2>&1 && echo "removed marketplace $m"
  done
fi

# graphify: its own uninstaller removes its skill and its section in ~/.claude/CLAUDE.md.
# Run from a temp folder so it can't touch files in the folder you're in.
if has graphify; then
  (cd "$(mktemp -d)" && graphify uninstall >/dev/null 2>&1) && echo "removed graphify skill"
fi
if has uv && uv tool list 2>/dev/null | grep -q '^graphifyy '; then
  uv tool uninstall graphifyy >/dev/null 2>&1 && echo "removed graphify CLI"
elif has pipx && pipx list 2>/dev/null | grep -q graphifyy; then
  pipx uninstall graphifyy >/dev/null 2>&1 && echo "removed graphify CLI"
fi

# headroom: undo any wrap setup it made for Claude Code, then remove the CLI.
if has headroom; then
  (cd "$(mktemp -d)" && headroom unwrap claude >/dev/null 2>&1) || true
fi
if has uv && uv tool list 2>/dev/null | grep -q '^headroom-ai '; then
  uv tool uninstall headroom-ai >/dev/null 2>&1 && echo "removed headroom"
fi

echo "done. Run /reload-plugins in open Claude Code chats."
