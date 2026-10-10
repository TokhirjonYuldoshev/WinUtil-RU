BeforeAll {
    $root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $script:prepare = Get-Content (Join-Path $root 'tools/automation/Prepare-WinUtilRussianCandidate.ps1') -Raw -Encoding utf8
    $script:pipeline = Get-Content (Join-Path $root '.github/workflows/upstream-ru-release-pipeline.yaml') -Raw -Encoding utf8
    $script:promotion = Get-Content (Join-Path $root '.github/workflows/ru-stable-promotion.yaml') -Raw -Encoding utf8
    $script:legacyBuild = Get-Content (Join-Path $root '.github/workflows/russian-release.yaml') -Raw -Encoding utf8
    $script:watch = Get-Content (Join-Path $root '.github/workflows/upstream-release-watch.yaml') -Raw -Encoding utf8
}

Describe 'WinUtil RU upstream automation safety contract' {
    It 'polls for official stable releases without trusting upstream main HEAD as a release' {
        $script:prepare | Should -Match 'repos/\$upstream/releases/latest'
        $script:prepare | Should -Match 'refs/tags/\$tag'
        $script:prepare | Should -Match 'Official GitHub tag mismatch'
        $script:prepare | Should -Match 'Assert-Ancestor'
        $script:pipeline | Should -Match '7,22,37,52 \* \* \* \*'
    }

    It 'requires safe fork main fast-forward and never force-pushes a live branch' {
        $script:prepare | Should -Match "'push','origin'"
        $script:prepare | Should -Match 'fork main fast-forward'
        $script:prepare | Should -Not -Match 'git push --force|push.{0,30}--force|git reset --hard'
        $script:prepare | Should -Match 'New upstream has overlapping changes requiring manual port'
    }

    It 'does not publish stable from a scheduled or pull-request pipeline' {
        $script:pipeline | Should -Match 'workflow_dispatch'
        $script:pipeline | Should -Match 'schedule:'
        $script:pipeline | Should -Match 'publish-rc:'
        $script:pipeline | Should -Match 'prerelease --latest=false'
        $script:pipeline | Should -Not -Match 'publish.stable|gh release create.{0,250} --latest[^\s=]'
    }

    It 'runs mandatory candidate tests and dispatches existing branch protection checks' {
        $script:prepare | Should -Match 'Ensure-RequiredCandidateChecks'
        $script:prepare | Should -Match 'unittests.yaml'
        $script:prepare | Should -Match 'compile-check.yaml'
        $script:prepare | Should -Match 'russian-parity-check.yaml'
        $script:pipeline | Should -Match 'Build-WinUtilRussianRelease.ps1 -Channel beta'
        $script:pipeline | Should -Match 'Pester tests \(PowerShell 7\)'
        $script:pipeline | Should -Match 'Windows PowerShell 5.1'
    }

    It 'requires explicit owner, manual dispatch, tested hash and immutable source' {
        $script:promotion | Should -Match 'workflow_dispatch:'
        $script:promotion | Should -Not -Match '(?m)^  (schedule|push|pull_request|release|workflow_run):'
        $script:promotion | Should -Match "github.actor == 'TokhirjonYuldoshev'"
        $script:promotion | Should -Match 'winutil-ru-stable'
        $script:promotion | Should -Match 'I_TESTED_THIS_RC'
        $script:promotion | Should -Match 'approved_sha256'
        $script:promotion | Should -Match 'RC binary not reproducible'
        $script:promotion | Should -Match 'Merged tree differs from approved candidate'
        $script:promotion | Should -Match '\-\-match-head-commit'
    }

    It 'keeps the legacy RU build read-only and rejects direct stable publication' {
        $script:legacyBuild | Should -Match 'Russian Release Build'
        $script:legacyBuild | Should -Match 'workflow_dispatch:'
        $script:legacyBuild | Should -Match 'contents: read'
        $script:legacyBuild | Should -Match 'Strict official-tag and backend parity preflight'
        $script:legacyBuild | Should -Match 'Build-WinUtilRussianRelease.ps1 -Channel stable'
        $script:legacyBuild | Should -Match 'Upload build artifact'
        $script:legacyBuild | Should -Match 'Validate release manifest'
        $script:legacyBuild | Should -Not -Match 'publish_stable'
        $script:legacyBuild | Should -Not -Match 'Publish-WinUtilRussianRelease'
        $script:legacyBuild | Should -Not -Match 'contents: write'
        $script:legacyBuild | Should -Not -Match 'gh release create'
        $script:promotion | Should -Match 'winutil-ru-stable'
    }

    It 'keeps the independent upstream watcher read-only' {
        $script:watch | Should -Match 'contents: read'
        $script:watch | Should -Not -Match 'contents: write'
        $script:watch | Should -Match '13 \*/6 \* \* \*'
    }

    It 'parses all automation PowerShell source files without executing them' {
        $folder = Join-Path $root 'tools/automation'
        foreach ($file in @(Get-ChildItem $folder -Filter '*.ps1' -File -Recurse)) {
            $tokens = $null
            $errors = $null
            [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors) | Out-Null
            @($errors).Count | Should -Be 0 -Because $file.Name
        }
    }
}
