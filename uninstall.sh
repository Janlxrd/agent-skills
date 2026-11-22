#!/usr/bin/env bash
# Remove what install.sh installed. Nothing else is touched.
#
#   curl -fsSL https://raw.githubusercontent.com/Janlxrd/agent-skills/main/uninstall.sh | bash
set -uo pipefail

SKILLS=(grill-me grilling agent-browser find-skills web-design-guidelines canvas-design seo-audit unslop anti-ui-slop design-taste-frontend)
has() { command -v "$1" >/dev/null 2>&1; }

# Skills, from every agent npx skills put them in.
if has npx; then
  args=(); for s in "${SKILLS[@]}"; do args+=(--skill "$s"); done
  npx -y skills@latest remove -g -y "${args[@]}" >/dev/null 2>&1 && echo "removed skills: ${SKILLS[*]}"
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

echo "done. Run /reload-plugins in open Claude Code chats."
