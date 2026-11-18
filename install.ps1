# Install all skills in this repo into ~/.agents/skills and ~/.claude/skills (Windows).
# Usage (PowerShell):
#   irm https://raw.githubusercontent.com/Janlxrd/agent-skills/main/install.ps1 | iex
#   or: git clone https://github.com/Janlxrd/agent-skills; .\agent-skills\install.ps1
$ErrorActionPreference = 'Stop'

$Repo = 'https://github.com/Janlxrd/agent-skills'
$Targets = @("$HOME\.agents\skills", "$HOME\.claude\skills")

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
  $skills = Get-ChildItem "$Src\plugins\agent-skills\skills" -Directory
  foreach ($t in $Targets) {
    New-Item -ItemType Directory -Force -Path $t | Out-Null
    foreach ($s in $skills) {
      $dest = Join-Path $t $s.Name
      if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
      Copy-Item -Recurse $s.FullName $dest
    }
    Write-Host "installed $($skills.Count) skills -> $t"
  }

  # anti-ui-slop is only published at uizze.com (not on GitHub), so pull it via the skills CLI.
  if (Get-Command npx -ErrorAction SilentlyContinue) {
    npx -y skills add https://uizze.com --skill anti-ui-slop -g -y
    if ($LASTEXITCODE -ne 0) { Write-Warning 'anti-ui-slop install failed' }
  } else { Write-Host 'skip: anti-ui-slop (needs npx / Node.js)' }

  # unslop as a Claude Code plugin too (skill copy above works either way).
  if (Get-Command claude -ErrorAction SilentlyContinue) {
    claude plugin marketplace add heydamir/unslop 2>$null | Out-Null
    claude plugin install unslop@heydamir
    if ($LASTEXITCODE -ne 0) { Write-Warning 'unslop plugin install failed' }
  }
  # token-saving-mods: Claude Code plugin pack, Windows build.
  # Copied to a fixed folder because a local marketplace points at its path.
  if (Get-Command claude -ErrorAction SilentlyContinue) {
    $dest = "$HOME\.claude\token-saving-mods"
    if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
    Copy-Item -Recurse "$Src\mods\windows\token-saving-mods" $dest
    claude plugin marketplace add $dest 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) { claude plugin marketplace update token-saving-mods 2>$null | Out-Null }
    $mods = 'input-router','effort-optimizer','model-router','cache-clock','handoff','research-router','efficient-browser-use','mods','savings-proof'
    foreach ($m in $mods) {
      claude plugin install "$m@token-saving-mods"
      if ($LASTEXITCODE -ne 0) { Write-Warning "$m install failed" }
    }
    Write-Host "installed token-saving-mods -> $dest (run /reload-plugins in open Claude Code chats)"
  } else { Write-Host 'skip: token-saving-mods (needs claude on PATH)' }
  Write-Host 'done.'
} finally {
  if ($Tmp) { Remove-Item -Recurse -Force $Tmp -ErrorAction SilentlyContinue }
}
