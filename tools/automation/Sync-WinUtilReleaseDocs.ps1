#requires -Version 7.0
[CmdletBinding()]
param([switch]$Check)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = 'TokhirjonYuldoshev/WinUtil-RU'
$upstream = 'ChrisTitusTech/winutil'
$headers = @{ Accept = 'application/vnd.github+json'; 'User-Agent' = 'WinUtil-RU-Docs-Sync' }
if ($env:GH_TOKEN) { $headers.Authorization = "Bearer $env:GH_TOKEN" }
function Read-GitHub([string]$path) {
  Invoke-RestMethod -Uri "https://api.github.com/$path" -Headers $headers -TimeoutSec 30
}
function Assert-Sha([string]$value) {
  if ($value -cnotmatch '^[a-f0-9]{40}$') { throw 'Invalid GitHub commit SHA' }
  return $value
}
function Sync-Block([string]$path, [string]$anchor, [string]$content) {
  $raw = [IO.File]::ReadAllText((Join-Path (Get-Location) $path))
  $begin = '<!-- WINUTIL-RU-DOCSYNC:START -->'
  $end = '<!-- WINUTIL-RU-DOCSYNC:END -->'
  $nl = [Environment]::NewLine
  $block = $begin + $nl + $content + $nl + $end
  $a = $raw.IndexOf($begin, [StringComparison]::Ordinal)
  $b = $raw.IndexOf($end, [StringComparison]::Ordinal)
  if (($a -ge 0) -ne ($b -ge 0)) { throw "Incomplete markers: $path" }
  if ($a -ge 0) {
    if ($raw.LastIndexOf($begin, [StringComparison]::Ordinal) -ne $a -or $raw.LastIndexOf($end, [StringComparison]::Ordinal) -ne $b -or $b -lt $a) {
      throw "Duplicate or reversed markers: $path"
    }
    $next = $raw.Substring(0, $a) + $block + $raw.Substring($b + $end.Length)
  } else {
    $at = $raw.IndexOf($anchor, [StringComparison]::Ordinal)
    if ($at -lt 0 -or $raw.LastIndexOf($anchor, [StringComparison]::Ordinal) -ne $at) {
      throw "Missing or ambiguous section: $path"
    }
    $next = $raw.Insert($at, $block + $nl + $nl)
  }
  if ($next -ne $raw) {
    if ($Check) { throw "Documentation drift: $path" }
    [IO.File]::WriteAllText((Join-Path (Get-Location) $path), $next, [Text.UTF8Encoding]::new($false))
  }
}
$ru = Read-GitHub "repos/$repo/releases/latest"
$official = Read-GitHub "repos/$upstream/releases/latest"
if ($ru.draft -or $ru.prerelease -or $official.draft -or $official.prerelease) { throw 'Not stable releases' }
$ruTag = [string]$ru.tag_name
$offTag = [string]$official.tag_name
if ($ruTag -cnotmatch '^([0-9]{2}[.][0-9]{2}[.][0-9]{2})-RU[.][1-9][0-9]*$') { throw 'Unrecognized RU release tag' }
$ruBase = $Matches[1]
if ($offTag -cnotmatch '^[0-9]{2}[.][0-9]{2}[.][0-9]{2}$') { throw 'Unrecognized upstream tag' }
$ruCommit = Assert-Sha ([string](Read-GitHub "repos/$repo/commits/$ruTag").sha)
$upCommit = Assert-Sha ([string](Read-GitHub "repos/$upstream/commits/$offTag").sha)
$assets = @($ru.assets | Where-Object { $_.name -ceq 'winutil-RU.ps1' })
if ($assets.Count -ne 1 -or [string]$assets[0].digest -cnotmatch '^sha256:[a-f0-9]{64}$') { throw 'Missing SHA256 release asset digest' }
$hash = ([string]$assets[0].digest).Substring(7)
$baseline = Get-Content 'tools/WinUtilUpstreamBaseline.json' -Raw -Encoding UTF8 | ConvertFrom-Json
if ($ruBase -cne [string]$baseline.Tag) { throw 'Published RU base differs from verified pinned baseline; manual review needed' }
$ruUrl = "https://github.com/$repo/releases/tag/$ruTag"
$upUrl = "https://github.com/$upstream/releases/tag/$offTag"
$ruText = @(
  'Автоматически проверенные данные опубликованных релизов GitHub (не заменяют Windows QA):'
  ''
  "- WinUtil-RU stable: [$ruTag]($ruUrl); commit $ruCommit."
  "- SHA256 опубликованного winutil-RU.ps1: $hash."
  "- Официальный stable WinUtil: [$offTag]($upUrl); commit $upCommit."
  "- Основа RU: $($baseline.Tag). Новый upstream stable требует отдельного RC и Windows QA."
) -join [Environment]::NewLine
$enText = @(
  'Verified published GitHub release metadata (not a substitute for Windows QA):'
  ''
  "- WinUtil-RU stable: [$ruTag]($ruUrl); commit $ruCommit."
  "- Published winutil-RU.ps1 SHA256: $hash."
  "- Official WinUtil stable: [$offTag]($upUrl); commit $upCommit."
  "- RU pinned upstream baseline: $($baseline.Tag). New upstream releases still require an RC and Windows QA."
) -join [Environment]::NewLine
Sync-Block 'README.md' '## Быстрый запуск' $ruText
Sync-Block 'README.en.md' '## Quick start' $enText
Sync-Block 'docs/README-RU.md' '## Запуск через загрузчик' $ruText
Sync-Block 'docs/AUTOMATION-RU.md' '## Цель и разделение полномочий' $ruText
Write-Host "Docs sync verified $ruTag; SHA256 $hash; upstream $offTag"
