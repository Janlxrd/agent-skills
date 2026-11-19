# agent-skills

My agent skills and always-on rules in one Claude Code plugin, plus an install script for other tools.

## What's in it

One plugin, **`agent-skills`**:
- **Skills** in [`plugins/agent-skills/skills/`](plugins/agent-skills/skills). Claude uses one when a task calls for it, or you type `/name`.
- **Rules** in [`plugins/agent-skills/rules.md`](plugins/agent-skills/rules.md), loaded at the start of every Claude Code chat:
  - **Coding:** the [Karpathy guidelines](https://github.com/multica-ai/andrej-karpathy-skills) (MIT): ask before assuming, keep it simple, make small changes, check your work.
  - **Writing:** plain, human-sounding text. No filler, no hype words, no em dashes, no emoji.

The rules never edit your own `~/.claude/CLAUDE.md`. Whatever you keep there still works alongside them.

## Install in Claude Code

Add the marketplace and install the one plugin:
- **claude.ai/plugins:** Add marketplace → `Janlxrd/agent-skills` → install **agent-skills**. Keep "Sync automatically" on so pushes show up in new sessions.
- **Claude Code:**

  ```
  /plugin install agent-skills --marketplace Janlxrd/agent-skills
  ```

To pick up a change in a chat that's already open, run `/reload-plugins`. New chats get it automatically.

## Install script (Claude Code + other tools + mods)

**macOS / Linux**

```bash
curl -fsSL https://raw.githubusercontent.com/Janlxrd/agent-skills/main/install.sh | bash
```

**Windows (PowerShell)**

```powershell
irm https://raw.githubusercontent.com/Janlxrd/agent-skills/main/install.ps1 | iex
```

Requires git. You can also clone the repo and run `./install.sh` or `.\install.ps1`.

By default the script:
- installs the **agent-skills plugin** in Claude Code (same as above)
- copies the skill files into `~/.agents/skills/` (read by Codex, Cline, Warp, Zed, Kimi and others), and into **Cursor, Gemini CLI, GitHub Copilot, Windsurf and OpenCode** if it finds them installed
- installs the token-saving mods (9 Claude Code plugins) for your OS: `mods/mac/` on macOS, `mods/windows/` on Windows. Skipped on Linux. Run `/reload-plugins`, then `/mods` to check them.
- cleans up anything older versions of the script installed (copies in `~/.claude/skills`, the old `global-rules` and heydamir `unslop` plugins, the old block in `~/.claude/CLAUDE.md`), so nothing loads twice. Your own files and skills are left alone.

| What you want | macOS / Linux | Windows |
|---|---|---|
| Skill files only, no plugin, rules or mods | `--skills-only` | `-SkillsOnly` |
| Just some skill files | `--only grill-me,unslop` | `-Only grill-me,unslop` |
| Everything except the mods | `--no-mods` | `-NoMods` |
| Skill files into every tool, even ones not found | `--all-tools` | `-AllTools` |
| Skill files only into `~/.agents/skills` | `--no-tools` | `-NoTools` |
| List skill names | `--list` | `-List` |

With the one-liners:

```bash
curl -fsSL https://raw.githubusercontent.com/Janlxrd/agent-skills/main/install.sh | bash -s -- --no-mods
```

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Janlxrd/agent-skills/main/install.ps1))) -NoMods
```

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
| anti-ui-slop | [uizze.com](https://uizze.com) (not on GitHub, so update it by hand) |

Each skill keeps its upstream license (`LICENSE.upstream` or `LICENSE.txt` in its folder).

## Token-saving mods

input-router, effort-optimizer, model-router, cache-clock, handoff, research-router, efficient-browser-use, mods, savings-proof. See `mods/<os>/token-saving-mods/INSTALL.md` for optional extras (Poppler, Firecrawl). The Windows build hasn't been tested on a Windows machine yet. To update them, replace the folder under `mods/` with the new pack and re-run the installer.

## Updating

```bash
./update.sh && git commit -am "update skills" && git push
```

`update.sh` re-pulls each skill from the repo listed in `sources.txt`. To add a skill, add a line there and run it. anti-ui-slop isn't on GitHub: to update it, run `npx skills add https://uizze.com --skill anti-ui-slop -g -y` and copy the new folder over `plugins/agent-skills/skills/anti-ui-slop`.
