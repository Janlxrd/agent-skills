# agent-skills

Scripts that install my agent skills, the Karpathy coding rules, graphify and headroom, each from its own source. Nothing is stored in this repo, so you always get the latest version from the people who make them.

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
- **The skills** below, with [`npx skills`](https://github.com/vercel-labs/skills). It puts each one into every agent it finds on your machine (Claude Code, Cursor, Codex, Gemini CLI, Copilot, Windsurf, OpenCode and others).
- **The Karpathy coding rules**, as their own Claude Code plugin from [multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills). Needs Claude Code, which you install yourself.
- **[graphify](https://github.com/Graphify-Labs/graphify)**, which turns a codebase into a knowledge graph (type `/graphify .`). Installed with `uv` or `pipx`, then its own `graphify install` adds the skill. It also adds a short graphify section to `~/.claude/CLAUDE.md`.
- **[headroom](https://github.com/chopratejas/headroom)**, which cuts the tokens Claude Code sends by compressing context through a local proxy. The script only installs it (with `uv`). To use it, start Claude with `headroom wrap claude` instead of `claude`.
- **[claude-red](https://github.com/SnailSploit/claude-red)**, 79 offensive-security skills (web, wifi, cloud, AD, and more) for authorized pentesting. All of them, into every agent. Skip with `--no-red` / `-NoRed`.

It also installs the tools those need if you don't have them:
- **Windows:** Git and Node.js (with winget, so Windows may ask for permission), and [uv](https://docs.astral.sh/uv/).
- **macOS:** Node.js (with Homebrew, if you have it) and uv.
- **Linux:** uv. Install Node.js yourself first.

When it's done, open a new terminal so `graphify` and `headroom` work. Anything it can't install is skipped with a message. Your own skills and the rest of your `CLAUDE.md` are never touched. If you used an older version of this repo, the script also removes the old `agent-skills` plugin and the skill copies it made, so nothing loads twice.

| What you want | macOS / Linux | Windows |
|---|---|---|
| Just some skills | `--only grill-me,unslop` | `-Only grill-me,unslop` |
| Skip the Karpathy rules | `--no-rules` | `-NoRules` |
| Skip graphify | `--no-graphify` | `-NoGraphify` |
| Skip headroom | `--no-headroom` | `-NoHeadroom` |
| Skip claude-red | `--no-red` | `-NoRed` |
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
| design-taste-frontend (Taste Skill) | [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill) |
| humanizer | [blader/humanizer](https://github.com/blader/humanizer) |
| claude-red (79 offensive-security skills, all named `offensive-*`) | [SnailSploit/claude-red](https://github.com/SnailSploit/claude-red) |

## RAPTOR (not installed by this script)

[RAPTOR](https://github.com/gadievron/raptor) is a security-research framework, not a skill, so the install script leaves it alone. You run it from its own checkout. The quickest route is Docker:

```bash
git clone --branch v3.1.0 https://github.com/gadievron/raptor.git
cd raptor
docker pull docker.io/danielcuthbert/raptor:latest
docker run -it -v "$PWD:/workspaces/raptor" docker.io/danielcuthbert/raptor:latest
```

Inside the container, run `raptor`. For a setup without Docker (Python 3.13, uv, Semgrep, Node.js), see its [installation docs](https://github.com/gadievron/raptor/blob/main/docs/installation.md).

## Update

Re-run the install script, or update just the skills:

```bash
npx skills update -g
```

## Uninstall

Removes the skills above, claude-red (every `offensive-*` skill), the Karpathy rules plugin, graphify (including its section in `~/.claude/CLAUDE.md`) and headroom. Nothing else.

**macOS / Linux**

```bash
curl -fsSL https://raw.githubusercontent.com/Janlxrd/agent-skills/main/uninstall.sh | bash
```

**Windows (PowerShell)**

```powershell
irm https://raw.githubusercontent.com/Janlxrd/agent-skills/main/uninstall.ps1 | iex
```
