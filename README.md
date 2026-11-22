# agent-skills

Scripts that install my agent skills, the Karpathy coding rules and graphify, each from its own source. Nothing is stored in this repo, so you always get the latest version from the people who make them.

## Install

**macOS / Linux**

```bash
curl -fsSL https://raw.githubusercontent.com/Janlxrd/agent-skills/main/install.sh | bash
```

**Windows (PowerShell)**

```powershell
irm https://raw.githubusercontent.com/Janlxrd/agent-skills/main/install.ps1 | iex
```

The script installs:
- **The skills** below, with [`npx skills`](https://github.com/vercel-labs/skills). It puts each one into every agent it finds on your machine (Claude Code, Cursor, Codex, Gemini CLI, Copilot, Windsurf, OpenCode and others). Needs [Node.js](https://nodejs.org).
- **The Karpathy coding rules**, as their own Claude Code plugin from [multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills). Needs Claude Code.
- **[graphify](https://github.com/Graphify-Labs/graphify)**, which turns a codebase into a knowledge graph (type `/graphify .`). Installed with `uv` or `pipx`, then its own `graphify install` adds the skill. It also adds a short graphify section to `~/.claude/CLAUDE.md`. Needs [uv](https://docs.astral.sh/uv/) or pipx.

Anything it can't install (say, no Node.js) is skipped with a message. Your own skills and the rest of your `CLAUDE.md` are never touched. If you used an older version of this repo, the script also removes the old `agent-skills` plugin and the skill copies it made, so nothing loads twice.

| What you want | macOS / Linux | Windows |
|---|---|---|
| Just some skills | `--only grill-me,unslop` | `-Only grill-me,unslop` |
| Skip the Karpathy rules | `--no-rules` | `-NoRules` |
| Skip graphify | `--no-graphify` | `-NoGraphify` |
| List skill names | `--list` | `-List` |

With the one-liners:

```bash
curl -fsSL https://raw.githubusercontent.com/Janlxrd/agent-skills/main/install.sh | bash -s -- --no-graphify
```

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Janlxrd/agent-skills/main/install.ps1))) -NoGraphify
```

Run `/reload-plugins` in any Claude Code chat that was already open.

## Skills

| Skill | From |
|---|---|
| grill-me (type `/grill-me`) | [mattpocock/skills](https://github.com/mattpocock/skills) |
| grilling | [mattpocock/skills](https://github.com/mattpocock/skills) |
| agent-browser | [vercel-labs/agent-browser](https://github.com/vercel-labs/agent-browser) |
| find-skills | [vercel-labs/skills](https://github.com/vercel-labs/skills) |
| web-design-guidelines | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) |
| canvas-design | [anthropics/skills](https://github.com/anthropics/skills) |
| seo-audit | [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills) |
| unslop | [heydamir/unslop](https://github.com/heydamir/unslop) |
| anti-ui-slop | [uizze.com](https://uizze.com) |

## Update

Re-run the install script, or update just the skills:

```bash
npx skills update -g
```

## Uninstall

Removes the skills above, the Karpathy rules plugin and graphify (including its section in `~/.claude/CLAUDE.md`). Nothing else.

**macOS / Linux**

```bash
curl -fsSL https://raw.githubusercontent.com/Janlxrd/agent-skills/main/uninstall.sh | bash
```

**Windows (PowerShell)**

```powershell
irm https://raw.githubusercontent.com/Janlxrd/agent-skills/main/uninstall.ps1 | iex
```
