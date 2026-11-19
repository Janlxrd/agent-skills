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
- the `global-rules` plugin (see [Rules](#rules) below), if `claude` is on your PATH
- the token-saving mods (9 Claude Code plugins) for your OS, if `claude` is on your PATH: `mods/mac/` on macOS, `mods/windows/` on Windows. They're copied to `~/.claude/token-saving-mods` and added as a local plugin marketplace. Run `/reload-plugins` in any open Claude Code chat, then `/mods` to check them. Skipped on Linux.

### Install only some of it

| What you want | macOS / Linux | Windows |
|---|---|---|
| Skills only, no plugins or mods | `--skills-only` | `-SkillsOnly` |
| Everything except the mods | `--no-mods` | `-NoMods` |
| Everything except the unslop plugin | `--no-plugins` | `-NoPlugins` |
| Everything except the global-rules plugin | `--no-rules` | `-NoRules` |
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

## Install as Claude Code plugins

The repo is a plugin marketplace with two plugins:

| Plugin | What it is |
|---|---|
| `agent-skills` | The skills. Claude uses one when a task calls for it. |
| `global-rules` | Always-on rules, loaded at the start of every chat. |

In Claude Code:

```
/plugin install agent-skills --marketplace Janlxrd/agent-skills
/plugin install global-rules --marketplace Janlxrd/agent-skills
```

Or add `Janlxrd/agent-skills` as a marketplace (claude.ai/plugins → Add marketplace, or `claude plugin marketplace add Janlxrd/agent-skills`) and install either one from there. anti-ui-slop isn't included; use the install script for that.

If you use the install script, you don't need the `agent-skills` plugin too. The script already copies the same skills.

## Rules

[`plugins/global-rules/rules.md`](plugins/global-rules/rules.md) holds the always-on rules:
- **Coding:** the [Karpathy guidelines](https://github.com/multica-ai/andrej-karpathy-skills) (MIT): ask before assuming, keep it simple, make small changes, check your work.
- **Writing:** plain, human-sounding text. No filler, no hype words, no em dashes, no emoji.

The plugin feeds that file to Claude at the start of each Claude Code chat. It never edits your own `~/.claude/CLAUDE.md`, so whatever you keep there still works alongside it. To stop the rules, turn off `global-rules` in `/plugin`. To change them, edit `rules.md` and push.

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
| anti-ui-slop | [uizze.com](https://uizze.com) (installed via npx) |

Each skill keeps its upstream license (`LICENSE.upstream` or `LICENSE.txt` in its folder).

## Token-saving mods

input-router, effort-optimizer, model-router, cache-clock, handoff, research-router, efficient-browser-use, mods, savings-proof. See `mods/<os>/token-saving-mods/INSTALL.md` for optional extras (Poppler, Firecrawl). The Windows build hasn't been tested on a Windows machine yet. To update them, replace the folder under `mods/` with the new pack and re-run the installer.

## Updating

```bash
./update.sh && git commit -am "update skills" && git push
```

`update.sh` re-pulls each skill from the repo listed in `sources.txt`. To add a skill, add a line there and run it.
