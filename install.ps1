# Install my agent skills, the Karpathy coding rules and graphify, each from its own source. Windows.
#
#   irm https://raw.githubusercontent.com/Janlxrd/agent-skills/main/install.ps1 | iex
#   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/Janlxrd/agent-skills/main/install.ps1))) -NoGraphify
#
# Run with -Help for all options.
param(
  [string[]]$Only,       # just these skills
  [switch]$NoRules,      # skip the Karpathy rules plugin
  [switch]$NoGraphify,   # skip graphify
  [switch]$NoHeadroom,   # skip headroom
  [switch]$List,         # list the skills and exit
  [switch]$Help
)
$ErrorActionPreference = 'Continue'

# source, skill. Installed with the skills CLI (npx skills), which copies each
# skill into every agent it finds (Claude Code, Cursor, Codex, Gemini CLI, ...).
$Skills = @(
  @('mattpocock/skills',             'grill-me'),
  @('mattpocock/skills',             'grilling'),
  @('vercel-labs/agent-browser',     'agent-browser'),
  @('vercel-labs/skills',            'find-skills'),
  @('vercel-labs/agent-skills',      'web-design-guidelines'),
  @('anthropics/skills',             'canvas-design'),
  @('coreyhaines31/marketingskills', 'seo-audit'),
  @('heydamir/unslop',               'unslop'),
  @('https://uizze.com',             'anti-ui-slop'),
  @('Leonxlnx/taste-skill',          'design-taste-frontend'),
  @('blader/humanizer',              'humanizer')
)

if ($Help) {
  @'
Usage: install.ps1 [options]

Installs, each from its own source:
  - the skills, with npx skills (needs Node.js)
  - the Karpathy coding rules plugin for Claude Code (needs claude)
  - graphify, with uv or pipx (needs one of them)
  - headroom, with uv (needs uv). Start Claude with: headroom wrap claude

Options
  -Only a,b,c    Just these skills. See -List.
  -NoRules       Skip the Karpathy rules plugin.
  -NoGraphify    Skip graphify.
  -NoHeadroom    Skip headroom.
  -List          List the skills and exit.
  -Help          Show this help.
'@ | Write-Host
  return
}
if ($List) { $Skills | ForEach-Object { $_[1] }; return }

function Has($name) { [bool](Get-Command $name -ErrorAction SilentlyContinue) }
# Run a program quietly; true if it worked.
function Run { $exe, $rest = $args; & $exe @rest *> $null; $LASTEXITCODE -eq 0 }
# npx.cmd, not npx.ps1, so a strict execution policy doesn't block it.
$Npx = if (Has 'npx.cmd') { 'npx.cmd' } elseif (Has 'npx') { 'npx' } else { $null }

# Pick the skills.
$Want = @()
if ($Only) {
  foreach ($r in ($Only -join ',').Split(',')) {
    $r = $r.Trim(); if (-not $r) { continue }
    $found = $Skills | Where-Object { $_[1] -eq $r }
    if (-not $found) { Write-Host "unknown skill: $r (see -List)"; return }
    $Want += ,$found
  }
} else {
  $Want = $Skills
}

# Older versions of this repo shipped its own copy of the skills as a plugin and
# as copied folders. Remove those so nothing loads twice. Only our skill names
# are touched; your own skills stay.
if (Has 'claude') {
  $installed = (& claude plugin list 2>$null) -join "`n"
  foreach ($p in 'agent-skills@janlxrd', 'global-rules@janlxrd', 'unslop@heydamir') {
    if ($installed.Contains($p) -and (Run claude plugin uninstall $p)) { Write-Host "removed old plugin $p" }
  }
  if (Run claude plugin marketplace remove janlxrd) { Write-Host 'removed old marketplace janlxrd' }
}
$dirs = "$HOME\.claude\skills", "$HOME\.cursor\skills", "$HOME\.gemini\skills", "$HOME\.copilot\skills",
        "$HOME\.codeium\windsurf\skills", "$HOME\.config\opencode\skills"
foreach ($dir in $dirs) {
  foreach ($name in @($Want | ForEach-Object { $_[1] }) + 'karpathy-guidelines') {
    $p = Join-Path $dir $name
    if (-not (Test-Path $p)) { continue }
    # Real folders only: links made by npx skills are left for it to manage.
    if ((Get-Item $p -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { continue }
    Remove-Item $p -Recurse -Force
    Write-Host "removed old copy $p"
  }
}
$md = "$HOME\.claude\CLAUDE.md"
$start = '<!-- agent-skills:start -->'; $end = '<!-- agent-skills:end -->'
if ((Test-Path $md) -and ([IO.File]::ReadAllText($md)).Contains($start)) {
  Copy-Item $md "$md.bak" -Force
  $kept = [regex]::Replace([IO.File]::ReadAllText($md), '(?s)\r?\n?' + [regex]::Escape($start) + '.*?' + [regex]::Escape($end) + '\r?\n?', [Environment]::NewLine).TrimEnd()
  [IO.File]::WriteAllText($md, $(if ($kept) { $kept + [Environment]::NewLine } else { '' }), (New-Object System.Text.UTF8Encoding $false))
  Write-Host "removed old agent-skills block from $md (backup: $md.bak)"
}

# Skills.
if ($Npx) {
  foreach ($s in $Want) {
    if (Run $Npx -y skills@latest add $s[0] --skill $s[1] -g -y) {
      Write-Host "installed $($s[1]) from $($s[0])"
    } else {
      Write-Host "warn: $($s[1]) failed. Try: npx skills add $($s[0]) --skill $($s[1]) -g"
    }
  }
} else {
  Write-Host 'skip: skills (needs Node.js for npx: https://nodejs.org)'
}

# Karpathy coding rules: their own Claude Code plugin.
if (-not $NoRules -and -not $Only) {
  if (Has 'claude') {
    if (-not (Run claude plugin marketplace add multica-ai/andrej-karpathy-skills)) { $null = Run claude plugin marketplace update karpathy-skills }
    if (Run claude plugin install andrej-karpathy-skills@karpathy-skills) {
      Write-Host 'installed Karpathy rules plugin from multica-ai/andrej-karpathy-skills'
    } else {
      Write-Host 'warn: Karpathy rules plugin install failed'
    }
  } else {
    Write-Host 'skip: Karpathy rules plugin (needs claude on PATH)'
  }
}

# graphify: Python CLI, then its own installer adds the skill to Claude Code.
# Run from a temp folder so it can't touch files in the folder you're in.
if (-not $NoGraphify -and -not $Only) {
  $ok = $false
  if (Has 'uv') { $ok = Run uv tool install --upgrade graphifyy }
  elseif (Has 'pipx') { $ok = (Run pipx install graphifyy) -or (Run pipx upgrade graphifyy) }
  if ($ok -and (Has 'graphify')) {
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid())
    New-Item -ItemType Directory $tmp | Out-Null
    Push-Location $tmp
    if (Run graphify install) { Write-Host 'installed graphify (type /graphify . in Claude Code)' } else { Write-Host 'warn: graphify install failed' }
    Pop-Location
    Remove-Item $tmp -Recurse -Force
  } elseif ($ok) {
    Write-Host "warn: graphify installed but isn't on PATH yet. Open a new terminal and run: graphify install"
  } else {
    Write-Host 'skip: graphify (needs uv or pipx: https://docs.astral.sh/uv/)'
  }
}

# headroom: cuts the tokens Claude Code sends by squeezing context through a local proxy.
# Only the CLI is installed; nothing changes until you start Claude with headroom wrap claude.
if (-not $NoHeadroom -and -not $Only) {
  if (Has 'uv') {
    if (Run uv tool install --upgrade --python 3.13 'headroom-ai[all]') {
      Write-Host 'installed headroom (start Claude with: headroom wrap claude)'
    } else {
      Write-Host 'warn: headroom install failed. Try: uv tool install --python 3.13 "headroom-ai[all]"'
    }
  } else {
    Write-Host 'skip: headroom (needs uv: https://docs.astral.sh/uv/)'
  }
}

Write-Host 'done. Run /reload-plugins in open Claude Code chats.'
