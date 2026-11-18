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

## Updating

```bash
./update.sh && git commit -am "update skills" && git push
```

`update.sh` re-pulls each skill from the repo listed in `sources.txt`. To add a skill, add a line there and run it.
