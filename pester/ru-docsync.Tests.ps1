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
