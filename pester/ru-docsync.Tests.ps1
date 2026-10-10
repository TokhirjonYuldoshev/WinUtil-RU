BeforeAll {
  $root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
  $script:sync = Get-Content (Join-Path $root 'tools/automation/Sync-WinUtilReleaseDocs.ps1') -Raw -Encoding UTF8
  $script:workflow = Get-Content (Join-Path $root '.github/workflows/ru-documentation-sync.yaml') -Raw -Encoding UTF8
}
Describe 'Documentation sync protection' {
  It 'only reads published releases and checks source identity and asset digest' {
    $script:sync | Should -Match 'releases/latest'
    $script:sync | Should -Match 'commits/\$ruTag'
    $script:sync | Should -Match 'commits/\$offTag'
    $script:sync | Should -Match 'sha256:\[a-f0-9\]\{64\}'
    $script:sync | Should -Match 'WinUtilUpstreamBaseline.json'
    $script:sync | Should -Match 'expectedBaseCommit'
    $script:sync | Should -Match 'actualBaseCommit'
    $script:sync | Should -Match 'release.json'
    $script:sync | Should -Match 'LICENSE'
  }
  It 'limits script writes to four named Markdown files and bounded markers' {
    $script:sync | Should -Match 'WINUTIL-RU-DOCSYNC:START'
    $script:sync | Should -Match 'WINUTIL-RU-DOCSYNC:END'
    $script:sync | Should -Match 'README.en.md'
    $script:sync | Should -Match 'docs/README-RU.md'
    $script:sync | Should -Match 'docs/AUTOMATION-RU.md'
    $script:sync | Should -Match 'All markers and file contents are validated before ANY file is written'
    $script:sync | Should -Match 'Get-SyncBlock'
    $script:sync | Should -Not -Match 'gh release create|git push|git reset|--force'
  }
  It 'runs scheduled or manually and uses isolated PRs without auto merge' {
    $script:workflow | Should -Match 'workflow_dispatch:'
    $script:workflow | Should -Match 'cron:'
    $script:workflow | Should -Match 'docs-sync-\$RUN_ID'
    $script:workflow | Should -Match 'git diff --check'
    $script:workflow | Should -Match 'gh pr create'
    $script:workflow | Should -Match 'git rev-parse origin/russian'
    $script:workflow | Should -Match 'fork-automation-safety.yaml'
    $script:workflow | Should -Not -Match 'gh pr merge|--admin|git push --force'
    $script:workflow | Should -Not -Match 'ru-stable-promotion.yaml'
  }
  It 'parses documentation sync PowerShell syntax' {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseInput($script:sync,[ref]$tokens,[ref]$errors) | Out-Null
    @($errors).Count | Should -Be 0
  }
}


Describe 'Offline release metadata synchronization' {
  BeforeEach {
    $script:fixture = Join-Path $TestDrive 'docs-fixture'
    $headings = @{
      'README.md' = '## Быстрый запуск'
      'README.en.md' = '## Quick start'
      'docs/README-RU.md' = '## Запуск через загрузчик'
      'docs/AUTOMATION-RU.md' = '## Цель и разделение полномочий'
    }
    foreach ($entry in $headings.GetEnumerator()) {
      $destination = Join-Path $script:fixture $entry.Key
      New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force | Out-Null
      [IO.File]::WriteAllText($destination, "# Test documentation" + [Environment]::NewLine + $entry.Value + [Environment]::NewLine + "Historical text must stay.")
    }
    $baselineDest = Join-Path $script:fixture 'tools/WinUtilUpstreamBaseline.json'
    New-Item -ItemType Directory -Path (Split-Path $baselineDest -Parent) -Force | Out-Null
    Copy-Item (Join-Path $root 'tools/WinUtilUpstreamBaseline.json') $baselineDest
    $script:protected = Join-Path $script:fixture 'backend.ps1'
    [IO.File]::WriteAllText($script:protected, 'KEEP EXACT BACKEND')
    $global:WinUtilRuDocsSyncTestAnswers = @{
      'repos/TokhirjonYuldoshev/WinUtil-RU/releases/latest' = [pscustomobject]@{
        draft = $false; prerelease = $false; tag_name = '26.10.07-RU.1'
        assets = @(
          [pscustomobject]@{ name='winutil-RU.ps1'; size=100; digest=('sha256:' + ('a' * 64)) },
          [pscustomobject]@{ name='release.json'; size=100 },
          [pscustomobject]@{ name='LICENSE'; size=100 }
        )
      }
      'repos/ChrisTitusTech/winutil/releases/latest' = [pscustomobject]@{
        draft = $false; prerelease = $false; tag_name = '26.10.07'
      }
      'repos/TokhirjonYuldoshev/WinUtil-RU/commits/26.10.07-RU.1' = [pscustomobject]@{
        sha = '1be881f8690aed8e9e4c230d4a0818fd8f311a95'
      }
      'repos/ChrisTitusTech/winutil/commits/26.10.07' = [pscustomobject]@{
        sha = '07ccd8e2e755a706f31569808b31f5b77acad6a9'
      }
    }
    Mock Invoke-RestMethod {
      param($Uri)
      $key = ([uri]$Uri).AbsolutePath.TrimStart('/')
      if (-not $global:WinUtilRuDocsSyncTestAnswers.ContainsKey($key)) { throw "Unexpected API path: $key" }
      return $global:WinUtilRuDocsSyncTestAnswers[$key]
    }
  }

  AfterEach {
    Remove-Variable -Name WinUtilRuDocsSyncTestAnswers -Scope Global -ErrorAction SilentlyContinue
  }

  It 'updates only four allowlisted Markdown files and leaves backend and historical text intact' {
    & (Join-Path $root 'tools/automation/Sync-WinUtilReleaseDocs.ps1') -Root $script:fixture
    foreach ($relative in @('README.md', 'README.en.md', 'docs/README-RU.md', 'docs/AUTOMATION-RU.md')) {
      $value = [IO.File]::ReadAllText((Join-Path $script:fixture $relative))
      $value | Should -Match 'WINUTIL-RU-DOCSYNC:START'
      $value | Should -Match 'Historical text must stay.'
    }
    [IO.File]::ReadAllText($script:protected) | Should -BeExactly 'KEEP EXACT BACKEND'
  }

  It 'is idempotent for unchanged release metadata' {
    $syncPath = Join-Path $root 'tools/automation/Sync-WinUtilReleaseDocs.ps1'
    & $syncPath -Root $script:fixture
    $before = [IO.File]::ReadAllText((Join-Path $script:fixture 'README.md'))
    & $syncPath -Root $script:fixture
    [IO.File]::ReadAllText((Join-Path $script:fixture 'README.md')) | Should -BeExactly $before
  }

  It 'does not write anything in Check mode when documentation drifts' {
    $target = Join-Path $script:fixture 'README.md'
    $before = [IO.File]::ReadAllText($target)
    { & (Join-Path $root 'tools/automation/Sync-WinUtilReleaseDocs.ps1') -Root $script:fixture -Check } | Should -Throw '*Documentation drift*'
    [IO.File]::ReadAllText($target) | Should -BeExactly $before
  }

  It 'validates all markers before writing to any file' {
    $target = Join-Path $script:fixture 'README.md'
    $before = [IO.File]::ReadAllText($target)
    [IO.File]::WriteAllText((Join-Path $script:fixture 'docs/AUTOMATION-RU.md'), 'Missing unique anchor')
    { & (Join-Path $root 'tools/automation/Sync-WinUtilReleaseDocs.ps1') -Root $script:fixture } | Should -Throw '*Missing or ambiguous section*'
    [IO.File]::ReadAllText($target) | Should -BeExactly $before
  }

  It 'rejects a pinned upstream SHA mismatch without modifying documentation' {
    $global:WinUtilRuDocsSyncTestAnswers['repos/ChrisTitusTech/winutil/commits/26.10.07'] = [pscustomobject]@{ sha = ('0' * 40) }
    $target = Join-Path $script:fixture 'README.md'
    $before = [IO.File]::ReadAllText($target)
    { & (Join-Path $root 'tools/automation/Sync-WinUtilReleaseDocs.ps1') -Root $script:fixture } | Should -Throw '*Pinned official upstream commit differs*'
    [IO.File]::ReadAllText($target) | Should -BeExactly $before
  }

  It 'rejects a missing release asset without modifying documentation' {
    $ru = $global:WinUtilRuDocsSyncTestAnswers['repos/TokhirjonYuldoshev/WinUtil-RU/releases/latest']
    $ru.assets = @($ru.assets | Where-Object { $_.name -ne 'LICENSE' })
    $target = Join-Path $script:fixture 'README.md'
    $before = [IO.File]::ReadAllText($target)
    { & (Join-Path $root 'tools/automation/Sync-WinUtilReleaseDocs.ps1') -Root $script:fixture } | Should -Throw '*Missing, duplicate, or empty release asset*'
    [IO.File]::ReadAllText($target) | Should -BeExactly $before
  }
}
