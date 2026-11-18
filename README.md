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

This copies every folder in `skills/` into `~/.agents/skills/` and `~/.claude/skills/` (`%USERPROFILE%\.agents\skills` etc. on Windows). It also:
- installs `anti-ui-slop` from uizze.com with `npx skills add` (it isn't on GitHub, so it isn't copied here)
- installs `unslop` as a Claude Code plugin, if `claude` is on your PATH
- installs the token-saving mods (9 Claude Code plugins) for your OS, if `claude` is on your PATH: `mods/mac/` from `install.sh` on macOS, `mods/windows/` from `install.ps1` on Windows. They're copied to `~/.claude/token-saving-mods` and added as a local plugin marketplace. Run `/reload-plugins` in any open Claude Code chat, then `/mods` to check them. Skipped on Linux.

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
