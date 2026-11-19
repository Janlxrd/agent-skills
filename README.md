# agent-skills

My agent skills in one place, so I can install them all with one command.

## Install

**macOS / Linux**

```bash
curl -fsSL https://raw.githubusercontent.com/Janlxrd/agent-skills/main/install.sh | bash
```

or

```bash
git clone https://github.com/Janlxrd/agent-skills && ./agent-skills/install.sh
```

**Windows (PowerShell)**

```powershell
irm https://raw.githubusercontent.com/Janlxrd/agent-skills/main/install.ps1 | iex
```

or

```powershell
git clone https://github.com/Janlxrd/agent-skills; .\agent-skills\install.ps1
```

Requires git. If scripts are blocked, run `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` first (the `irm | iex` one-liner doesn't need it).

By default this installs everything:
- every skill in `plugins/agent-skills/skills/`, copied into `~/.agents/skills/` (read by Codex, Cline, Warp, Zed, Kimi and others) and `~/.claude/skills/`
- the same skills into **Cursor, Gemini CLI, GitHub Copilot, Windsurf and OpenCode**, but only for the ones it finds installed on your machine
- `anti-ui-slop` from uizze.com via `npx skills add` (it isn't on GitHub, so it isn't copied here)
- `unslop` as a Claude Code plugin, if `claude` is on your PATH
- global rules into `~/.claude/CLAUDE.md`, so Claude follows them in every chat: the [Karpathy coding guidelines](https://github.com/multica-ai/andrej-karpathy-skills) plus a plain-writing section (no AI-sounding words, no filler). They're in [`claude/CLAUDE.md`](claude/CLAUDE.md). Anything you already have in that file is kept: the installer only adds or replaces its own block between `<!-- agent-skills:start -->` and `<!-- agent-skills:end -->`, and saves a `.bak` copy the first time.
- the token-saving mods (9 Claude Code plugins) for your OS, if `claude` is on your PATH: `mods/mac/` on macOS, `mods/windows/` on Windows. They're copied to `~/.claude/token-saving-mods` and added as a local plugin marketplace. Run `/reload-plugins` in any open Claude Code chat, then `/mods` to check them. Skipped on Linux.

### Install only some of it

| What you want | macOS / Linux | Windows |
|---|---|---|
| Skills only, no plugins or mods | `--skills-only` | `-SkillsOnly` |
| Everything except the mods | `--no-mods` | `-NoMods` |
| Everything except the unslop plugin | `--no-plugins` | `-NoPlugins` |
| Everything except `~/.claude/CLAUDE.md` | `--no-claude-md` | `-NoClaudeMd` |
| Just some skills | `--only grill-me,unslop` | `-Only grill-me,unslop` |
| Skills into every tool, even ones not found | `--all-tools` | `-AllTools` |
| Skills into Claude + `~/.agents` only | `--no-tools` | `-NoTools` |
| List skill names | `--list` | `-List` |

With the one-liners:

```bash
curl -fsSL https://raw.githubusercontent.com/Janlxrd/agent-skills/main/install.sh | bash -s -- --skills-only
```

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Janlxrd/agent-skills/main/install.ps1))) -SkillsOnly
```

## Install as a Claude Code plugin

In Claude Code:

```
/plugin install agent-skills --marketplace Janlxrd/agent-skills
```

Or add `Janlxrd/agent-skills` as a marketplace (Claude app: Plugins → Add marketplace; CLI: `claude plugin marketplace add Janlxrd/agent-skills`) and install `agent-skills` from it. This gives you every skill in `plugins/agent-skills/skills/` as one plugin, updated whenever the repo changes. (anti-ui-slop isn't included; use the install script for that.)

## Skills

| Skill | From |
|---|---|
| grill-me | [mattpocock/skills](https://github.com/mattpocock/skills) |
| grilling | [mattpocock/skills](https://github.com/mattpocock/skills) |
| agent-browser | [vercel-labs/agent-browser](https://github.com/vercel-labs/agent-browser) |
| find-skills | [vercel-labs/skills](https://github.com/vercel-labs/skills) |
| web-design-guidelines | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) |
| canvas-design | [anthropics/skills](https://github.com/anthropics/skills) |
| seo-audit | [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills) |
| unslop | [heydamir/unslop](https://github.com/heydamir/unslop) |
| karpathy-guidelines | [multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills) |
| anti-ui-slop | [uizze.com](https://uizze.com) (installed via npx) |

Each skill keeps its upstream license (`LICENSE.upstream` or `LICENSE.txt` in its folder).

## Token-saving mods

input-router, effort-optimizer, model-router, cache-clock, handoff, research-router, efficient-browser-use, mods, savings-proof. See `mods/<os>/token-saving-mods/INSTALL.md` for optional extras (Poppler, Firecrawl). The Windows build hasn't been tested on a Windows machine yet. To update them, replace the folder under `mods/` with the new pack and re-run the installer.

## Updating

```bash
./update.sh && git commit -am "update skills" && git push
```

`update.sh` re-pulls each skill from the repo listed in `sources.txt`. To add a skill, add a line there and run it.
