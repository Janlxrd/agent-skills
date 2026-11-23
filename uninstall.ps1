# Remove what install.ps1 installed. Nothing else is touched. Windows.
#
#   irm https://raw.githubusercontent.com/Janlxrd/agent-skills/main/uninstall.ps1 | iex
$ErrorActionPreference = 'Continue'

$Skills = 'grill-me', 'grilling', 'agent-browser', 'find-skills', 'web-design-guidelines', 'canvas-design', 'seo-audit', 'unslop', 'anti-ui-slop', 'design-taste-frontend', 'humanizer'
function Has($name) { [bool](Get-Command $name -ErrorAction SilentlyContinue) }
# where uv puts graphify and headroom
if (Test-Path "$HOME\.local\bin") { $env:Path = "$HOME\.local\bin;$env:Path" }
function Run { $exe, $rest = $args; & $exe @rest *> $null; $LASTEXITCODE -eq 0 }
$Npx = if (Has 'npx.cmd') { 'npx.cmd' } elseif (Has 'npx') { 'npx' } else { $null }

# Skills, from every agent npx skills put them in.
if ($Npx) {
  $a = @(); foreach ($s in $Skills) { $a += '--skill', $s }
  if (Run $Npx -y skills@latest remove -g -y @a) { Write-Host "removed skills: $($Skills -join ' ')" }
} else {
  Write-Host 'skip: skills (needs Node.js for npx)'
}

# Karpathy rules plugin, plus the old plugins from this repo.
if (Has 'claude') {
  $installed = (& claude plugin list 2>$null) -join "`n"
  foreach ($p in 'andrej-karpathy-skills@karpathy-skills', 'agent-skills@janlxrd', 'global-rules@janlxrd') {
    if ($installed.Contains($p) -and (Run claude plugin uninstall $p)) { Write-Host "removed plugin $p" }
  }
  foreach ($m in 'karpathy-skills', 'janlxrd') {
    if (Run claude plugin marketplace remove $m) { Write-Host "removed marketplace $m" }
  }
}

# graphify: its own uninstaller removes its skill and its section in ~/.claude/CLAUDE.md.
# Run from a temp folder so it can't touch files in the folder you're in.
if (Has 'graphify') {
  $tmp = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid())
  New-Item -ItemType Directory $tmp | Out-Null
  Push-Location $tmp
  if (Run graphify uninstall) { Write-Host 'removed graphify skill' }
  Pop-Location
  Remove-Item $tmp -Recurse -Force
}
if ((Has 'uv') -and ((& uv tool list 2>$null) -match '^graphifyy ')) {
  if (Run uv tool uninstall graphifyy) { Write-Host 'removed graphify CLI' }
} elseif ((Has 'pipx') -and ((& pipx list 2>$null) -match 'graphifyy')) {
  if (Run pipx uninstall graphifyy) { Write-Host 'removed graphify CLI' }
}

# headroom: undo any wrap setup it made for Claude Code, then remove the CLI.
if (Has 'headroom') {
  $tmp = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid())
  New-Item -ItemType Directory $tmp | Out-Null
  Push-Location $tmp
  $null = Run headroom unwrap claude
  Pop-Location
  Remove-Item $tmp -Recurse -Force
}
if ((Has 'uv') -and ((& uv tool list 2>$null) -match '^headroom-ai ')) {
  if (Run uv tool uninstall headroom-ai) { Write-Host 'removed headroom' }
}

Write-Host 'done. Run /reload-plugins in open Claude Code chats.'
