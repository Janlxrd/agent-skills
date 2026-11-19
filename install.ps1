# Install the skills (and optionally the Claude Code plugins and mods) from this repo (Windows).
#
#   irm https://raw.githubusercontent.com/Janlxrd/agent-skills/main/install.ps1 | iex
#   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/Janlxrd/agent-skills/main/install.ps1))) -SkillsOnly
#   .\install.ps1 -Only grill-me,unslop
#
# Run with -Help for all options.
param(
  [switch]$SkillsOnly,   # only the skills: no Claude Code plugins, no mods
  [switch]$NoMods,       # skip the token-saving mods
  [switch]$NoPlugins,    # skip the unslop Claude Code plugin
  [switch]$NoClaudeMd,   # don't add the global rules to ~/.claude/CLAUDE.md
  [string[]]$Only,       # only these skills (implies -SkillsOnly)
  [switch]$AllTools,     # install into Cursor, Gemini CLI, etc. even if not found
  [switch]$NoTools,      # only ~/.agents/skills and ~/.claude/skills
  [switch]$List,         # list the skills and exit
  [switch]$Help
)
$ErrorActionPreference = 'Stop'

if ($Help) {
  @'
Usage: install.ps1 [options]

What to install (default: everything)
  -SkillsOnly        Only the skills. No Claude Code plugins, no mods.
  -NoMods            Skip the token-saving mods.
  -NoPlugins         Skip the unslop Claude Code plugin.
  -NoClaudeMd        Don't add the global rules to ~/.claude/CLAUDE.md.
  -Only a,b,c        Only these skills (implies -SkillsOnly). See -List.

-SkillsOnly and -Only also skip ~/.claude/CLAUDE.md.

Where skills go (default: ~/.agents/skills, ~/.claude/skills, plus any of
Cursor, Gemini CLI, GitHub Copilot, Windsurf, OpenCode found on this machine)
  -AllTools          Also install into those tools even if they aren't found.
  -NoTools           Only ~/.agents/skills and ~/.claude/skills.

  -List              List the skills and exit.
  -Help              Show this help.
'@ | Write-Host
  return
}

$Repo = 'https://github.com/Janlxrd/agent-skills'
$ModNames = 'input-router','effort-optimizer','model-router','cache-clock','handoff','research-router','efficient-browser-use','mods','savings-proof'

# Only also splits "a,b" passed as one string (e.g. from scriptblock calls).
if ($Only) { $Only = @($Only | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ }) }
if ($SkillsOnly -or $Only) { $NoMods = $true; $NoPlugins = $true; $NoClaudeMd = $true }

# Always installed to: ~/.agents/skills (Codex, Cline, Warp, Zed, Kimi, ...) and ~/.claude/skills.
$Targets = [System.Collections.Generic.List[string]]@("$HOME\.agents\skills", "$HOME\.claude\skills")
# Extra tools: name, folder that means it's installed, skills folder.
$Tools = @(
  @('Cursor',         "$HOME\.cursor",             "$HOME\.cursor\skills"),
  @('Gemini CLI',     "$HOME\.gemini",             "$HOME\.gemini\skills"),
  @('GitHub Copilot', "$HOME\.copilot",            "$HOME\.copilot\skills"),
  @('Windsurf',       "$HOME\.codeium\windsurf",   "$HOME\.codeium\windsurf\skills"),
  @('OpenCode',       "$HOME\.config\opencode",    "$HOME\.config\opencode\skills")
)
if (-not $NoTools) {
  foreach ($t in $Tools) { if ($AllTools -or (Test-Path $t[1])) { $Targets.Add($t[2]) } }
}

# Use the local checkout if run from one, else clone to a temp dir.
$Src = $PSScriptRoot
$Tmp = $null
if (-not $Src -or -not (Test-Path "$Src\plugins\agent-skills\skills")) {
  if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'git is required (https://git-scm.com/download/win)' }
  $Tmp = Join-Path ([IO.Path]::GetTempPath()) ("agent-skills-" + [guid]::NewGuid())
  git clone --depth 1 -q $Repo $Tmp
  if ($LASTEXITCODE -ne 0) { throw 'git clone failed' }
  $Src = $Tmp
}

try {
  $SkillsDir = "$Src\plugins\agent-skills\skills"
  $All = @(Get-ChildItem $SkillsDir -Directory | ForEach-Object { $_.Name }) + 'anti-ui-slop'

  if ($List) { $All | ForEach-Object { Write-Host $_ }; return }

  if ($Only) {
    foreach ($n in $Only) { if ($All -notcontains $n) { throw "unknown skill: $n (see -List)" } }
    $Want = $Only
  } else { $Want = $All }

  # Copy the bundled skills.
  foreach ($t in $Targets) {
    New-Item -ItemType Directory -Force -Path $t | Out-Null
    $count = 0
    foreach ($name in $Want) {
      $s = Join-Path $SkillsDir $name
      if (-not (Test-Path $s)) { continue }
      $dest = Join-Path $t $name
      if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
      Copy-Item -Recurse $s $dest
      $count++
    }
    Write-Host "installed $count skills -> $t"
  }

  # anti-ui-slop is only published at uizze.com, so pull it via the skills CLI.
  if ($Want -contains 'anti-ui-slop') {
    if (Get-Command npx -ErrorAction SilentlyContinue) {
      npx -y skills add https://uizze.com --skill anti-ui-slop -g -y
      if ($LASTEXITCODE -ne 0) { Write-Warning 'anti-ui-slop install failed' }
    } else { Write-Host 'skip: anti-ui-slop (needs npx / Node.js)' }
  }

  $HasClaude = [bool](Get-Command claude -ErrorAction SilentlyContinue)

  # unslop as a Claude Code plugin too (the skill copy above works either way).
  if (-not $NoPlugins -and $HasClaude) {
    claude plugin marketplace add heydamir/unslop 2>$null | Out-Null
    claude plugin install unslop@heydamir
    if ($LASTEXITCODE -ne 0) { Write-Warning 'unslop plugin install failed' }
  }

  # token-saving-mods: Claude Code plugin pack, Windows build.
  # Copied to a fixed folder because a local marketplace points at its path.
  if (-not $NoMods) {
    if ($HasClaude) {
      $dest = "$HOME\.claude\token-saving-mods"
      if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
      Copy-Item -Recurse "$Src\mods\windows\token-saving-mods" $dest
      claude plugin marketplace add $dest 2>$null | Out-Null
      if ($LASTEXITCODE -ne 0) { claude plugin marketplace update token-saving-mods 2>$null | Out-Null }
      foreach ($m in $ModNames) {
        claude plugin install "$m@token-saving-mods"
        if ($LASTEXITCODE -ne 0) { Write-Warning "$m install failed" }
      }
      Write-Host "installed token-saving-mods -> $dest (run /reload-plugins in open Claude Code chats)"
    } else { Write-Host 'skip: token-saving-mods (needs claude on PATH)' }
  }
  # Global rules (coding + writing) into ~/.claude/CLAUDE.md, between markers.
  # Anything else already in that file is left alone; only our block is replaced.
  if (-not $NoClaudeMd) {
    $md = "$HOME\.claude\CLAUDE.md"
    $start = '<!-- agent-skills:start -->'; $end = '<!-- agent-skills:end -->'
    New-Item -ItemType Directory -Force -Path "$HOME\.claude" | Out-Null
    $old = if (Test-Path $md) { [IO.File]::ReadAllText($md) } else { '' }
    if ($old.Trim() -and -not $old.Contains($start)) { Copy-Item $md "$md.bak" -Force; Write-Host "backed up $md -> $md.bak" }
    $kept = [regex]::Replace($old, '(?s)\r?\n?' + [regex]::Escape($start) + '.*?' + [regex]::Escape($end) + '\r?\n?', [Environment]::NewLine)
    $kept = $kept.TrimEnd()
    $ours = [IO.File]::ReadAllText("$Src\claude\CLAUDE.md").TrimEnd()
    $nl = [Environment]::NewLine
    $out = $(if ($kept) { $kept + $nl + $nl } else { '' }) + $start + $nl + $ours + $nl + $end + $nl
    [IO.File]::WriteAllText($md, $out, (New-Object System.Text.UTF8Encoding $false))
    Write-Host "installed global rules -> $md"
  }
  Write-Host 'done.'
} finally {
  if ($Tmp) { Remove-Item -Recurse -Force $Tmp -ErrorAction SilentlyContinue }
}
