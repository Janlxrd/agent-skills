# Install the agent-skills plugin (Claude Code), the skill files (other tools) and the mods. Windows.
#
#   irm https://raw.githubusercontent.com/Janlxrd/agent-skills/main/install.ps1 | iex
#   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/Janlxrd/agent-skills/main/install.ps1))) -SkillsOnly
#   .\install.ps1 -Only grill-me,unslop
#
# Run with -Help for all options.
param(
  [switch]$SkillsOnly,   # only skill files, everywhere: no plugin, no rules, no mods
  [string[]]$Only,       # like -SkillsOnly, but just these skills
  [switch]$NoMods,       # skip the token-saving mods
  [switch]$AllTools,     # copy skill files into Cursor, Gemini CLI, etc. even if not found
  [switch]$NoTools,      # skill files only into ~/.agents/skills
  [switch]$List,         # list the skills and exit
  [switch]$Help
)
$ErrorActionPreference = 'Stop'

if ($Help) {
  @'
Usage: install.ps1 [options]

By default:
  - Claude Code gets the agent-skills plugin (all skills + always-on coding
    and writing rules), installed from the Janlxrd/agent-skills marketplace.
  - Other tools get the skill files: ~/.agents/skills, plus Cursor, Gemini CLI,
    GitHub Copilot, Windsurf and OpenCode if they're installed.
  - The token-saving mods (Windows build).

Options
  -SkillsOnly        Only skill files, everywhere (incl. ~/.claude/skills).
                     No plugin, no rules, no mods.
  -Only a,b,c        Like -SkillsOnly, but just these skills. See -List.
  -NoMods            Skip the token-saving mods.
  -AllTools          Copy skill files into those tools even if they aren't found.
  -NoTools           Skill files only into ~/.agents/skills.
  -List              List the skills and exit.
  -Help              Show this help.
'@ | Write-Host
  return
}

$Repo = 'https://github.com/Janlxrd/agent-skills'
$ModNames = 'input-router','effort-optimizer','model-router','cache-clock','handoff','research-router','efficient-browser-use','mods','savings-proof'
$Retired = @('karpathy-guidelines')   # skills that used to be in this repo; old copies are removed

# Only also splits "a,b" passed as one string (e.g. from scriptblock calls).
if ($Only) { $Only = @($Only | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ }) }
$FilesOnly = [bool]($SkillsOnly -or $Only)
if ($FilesOnly) { $NoMods = $true }

$HasClaude = [bool](Get-Command claude -ErrorAction SilentlyContinue)
$UsePlugin = (-not $FilesOnly) -and $HasClaude

# Run claude without letting its stderr stop the script (Windows PowerShell 5.1 does that
# with ErrorActionPreference=Stop). Returns $true when it exits 0.
function Invoke-Claude {
  param([switch]$Quiet, [Parameter(ValueFromRemainingArguments)][string[]]$Rest)
  $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
  try {
    if ($Quiet) { & claude @Rest *> $null } else { & claude @Rest 2>&1 | Out-Host }
    return ($LASTEXITCODE -eq 0)
  } finally { $ErrorActionPreference = $old }
}

# Skill files always go to ~/.agents/skills (Codex, Cline, Warp, Zed, Kimi, ...).
# Claude Code gets them from the agent-skills plugin instead, unless -SkillsOnly/-Only
# is used or claude isn't installed, in which case they're copied to ~/.claude/skills.
$ClaudeSkills = "$HOME\.claude\skills"
$Targets = [System.Collections.Generic.List[string]]@("$HOME\.agents\skills")
if (-not $UsePlugin) { $Targets.Add($ClaudeSkills) }
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
  $All = @(Get-ChildItem $SkillsDir -Directory | ForEach-Object { $_.Name })

  if ($List) { $All | ForEach-Object { Write-Host $_ }; return }

  if ($Only) {
    foreach ($n in $Only) { if ($All -notcontains $n) { throw "unknown skill: $n (see -List)" } }
    $Want = $Only
  } else { $Want = $All }

  # Copy the skill files.
  foreach ($t in $Targets) {
    New-Item -ItemType Directory -Force -Path $t | Out-Null
    foreach ($r in $Retired) { $p = Join-Path $t $r; if (Test-Path $p) { Remove-Item -Recurse -Force $p } }
    $count = 0
    foreach ($name in $Want) {
      $s = Join-Path $SkillsDir $name
      if (-not (Test-Path $s)) { continue }
      $dest = Join-Path $t $name
      if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
      Copy-Item -Recurse $s $dest
      $count++
    }
    Write-Host "copied $count skills -> $t"
  }

  # agent-skills plugin for Claude Code: the skills plus always-on rules.
  if ($UsePlugin) {
    if (-not (Invoke-Claude -Quiet plugin marketplace add Janlxrd/agent-skills)) { Invoke-Claude -Quiet plugin marketplace update janlxrd | Out-Null }
    if (-not (Invoke-Claude plugin install agent-skills@janlxrd)) { Write-Warning 'agent-skills plugin install failed' }
    Invoke-Claude -Quiet plugin update agent-skills@janlxrd | Out-Null

    # Clean up what older versions of this script installed, so nothing loads twice.
    # Only folders/plugins this script put there are touched.
    foreach ($name in ($All + $Retired)) {
      $p = Join-Path $ClaudeSkills $name
      if (Test-Path $p) { Remove-Item -Recurse -Force $p; Write-Host "removed old copy $p (now in the plugin)" }
    }
    $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    $installed = (& claude plugin list 2>$null) -join "`n"
    $ErrorActionPreference = $old
    foreach ($p in 'global-rules@janlxrd','unslop@heydamir') {
      if ($installed -match [regex]::Escape($p)) {
        if (Invoke-Claude -Quiet plugin uninstall $p) { Write-Host "removed old plugin $p (now in agent-skills)" }
      }
    }
  } elseif (-not $FilesOnly) {
    Write-Host "skip: agent-skills plugin (needs claude on PATH); skill files copied to $ClaudeSkills instead"
  }

  # token-saving-mods: Claude Code plugin pack, Windows build.
  # Copied to a fixed folder because a local marketplace points at its path.
  if (-not $NoMods) {
    if ($HasClaude) {
      $dest = "$HOME\.claude\token-saving-mods"
      if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
      Copy-Item -Recurse "$Src\mods\windows\token-saving-mods" $dest
      if (-not (Invoke-Claude -Quiet plugin marketplace add $dest)) { Invoke-Claude -Quiet plugin marketplace update token-saving-mods | Out-Null }
      foreach ($m in $ModNames) {
        if (-not (Invoke-Claude plugin install "$m@token-saving-mods")) { Write-Warning "$m install failed" }
      }
      Write-Host "installed token-saving-mods -> $dest (run /reload-plugins in open Claude Code chats)"
    } else { Write-Host 'skip: token-saving-mods (needs claude on PATH)' }
  }

  # An older version of this script wrote the rules into ~/.claude/CLAUDE.md.
  # Remove only that marked block so the rules aren't loaded twice. Nothing else is touched.
  $md = "$HOME\.claude\CLAUDE.md"
  $start = '<!-- agent-skills:start -->'; $end = '<!-- agent-skills:end -->'
  if ((Test-Path $md) -and ([IO.File]::ReadAllText($md)).Contains($start)) {
    Copy-Item $md "$md.bak" -Force
    $kept = [regex]::Replace([IO.File]::ReadAllText($md), '(?s)\r?\n?' + [regex]::Escape($start) + '.*?' + [regex]::Escape($end) + '\r?\n?', [Environment]::NewLine).TrimEnd()
    [IO.File]::WriteAllText($md, $(if ($kept) { $kept + [Environment]::NewLine } else { '' }), (New-Object System.Text.UTF8Encoding $false))
    Write-Host "removed old agent-skills block from $md (backup: $md.bak)"
  }
  Write-Host 'done.'
} finally {
  if ($Tmp) { Remove-Item -Recurse -Force $Tmp -ErrorAction SilentlyContinue }
}
