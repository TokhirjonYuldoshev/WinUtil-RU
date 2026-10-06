BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    foreach ($file in @('bootstrap.ps1', 'run-russian.ps1')) {
        $tokens = $null; $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $repoRoot $file), [ref]$tokens, [ref]$errors)
        if ($errors.Count) { throw ($errors.Message -join '; ') }
        foreach ($definition in @($ast.EndBlock.Statements | Where-Object { $_ -is [System.Management.Automation.Language.FunctionDefinitionAst] })) {
            . ([scriptblock]::Create($definition.Extent.Text))
        }
    }
    $oldCommit = 'a' * 40
    $newCommit = 'b' * 40
    $locale = [pscustomobject]@{ Meta = [pscustomobject]@{ Version = '26.09.29-RU'; LocalizationVersion = '1.2.0' } }
    $originalLocalAppData = $env:LOCALAPPDATA
    $originalCommit = $env:WINUTIL_RU_COMMIT
    function New-TestLegacyCache {
        param([string]$Root)
        New-Item -ItemType Directory -Path $Root -Force | Out-Null
        $path = Join-Path $Root 'winutil-RU.ps1'
        [IO.File]::WriteAllText($path, 'old verified build')
        $manifest = @{ Version = '26.09.29-RU'; SourceCommit = $oldCommit; Sha256 = (Get-FileHash $path -Algorithm SHA256).Hash }
        $manifest | ConvertTo-Json | Set-Content (Join-Path $Root 'release.json')
        return $path
    }
}
AfterAll {
    $env:LOCALAPPDATA = $originalLocalAppData
    $env:WINUTIL_RU_COMMIT = $originalCommit
}
Describe 'Russian launcher safety' {
BeforeEach {
    $scenario = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $scenario | Out-Null
    $env:LOCALAPPDATA = $scenario
    $cacheRoot = Join-Path $scenario 'YTY/WindowManager/Stable'
    $compiled = Join-Path $scenario 'compiled.ps1'
    [IO.File]::WriteAllText($compiled, 'new validated build')
}

Describe 'Stable cache publication and recovery' {
    It 'keeps the old script and atomically publishes a matching immutable new build' {
        $old = New-TestLegacyCache $cacheRoot
        Publish-WinUtilStableCache -CompiledPath $compiled -CacheRoot $cacheRoot -SourceCommit $newCommit -Locale $locale
        [IO.File]::ReadAllText($old) | Should -Be 'old verified build'
        $current = Get-WMCachedBuild $cacheRoot
        $current.Manifest.SourceCommit | Should -Be $newCommit
        $current.ScriptPath | Should -Not -Be $old
        [IO.File]::ReadAllText($current.ScriptPath) | Should -Be 'new validated build'
        $backup = Get-Content (Join-Path $cacheRoot 'release.previous.json') -Raw | ConvertFrom-Json
        $backup.SourceCommit | Should -Be $oldCommit
    }
    It 'does not replace the working pointer when manifest creation fails' {
        $old = New-TestLegacyCache $cacheRoot
        $pointer = [IO.File]::ReadAllText((Join-Path $cacheRoot 'release.json'))
        Mock ConvertTo-Json { throw 'simulated manifest failure' }
        { Publish-WinUtilStableCache -CompiledPath $compiled -CacheRoot $cacheRoot -SourceCommit $newCommit -Locale $locale } | Should -Throw '*manifest failure*'
        [IO.File]::ReadAllText((Join-Path $cacheRoot 'release.json')) | Should -Be $pointer
        [IO.File]::ReadAllText($old) | Should -Be 'old verified build'
    }
    It 'refuses a corrupted pre-existing immutable artifact without changing the old pointer' {
        $null = New-TestLegacyCache $cacheRoot
        $hash = (Get-FileHash $compiled -Algorithm SHA256).Hash.ToLowerInvariant()
        $target = Join-Path $cacheRoot "versions/$newCommit-$hash/winutil-RU.ps1"
        New-Item -ItemType Directory (Split-Path $target) -Force | Out-Null
        [IO.File]::WriteAllText($target, 'corruption')
        { Publish-WinUtilStableCache -CompiledPath $compiled -CacheRoot $cacheRoot -SourceCommit $newCommit -Locale $locale } | Should -Throw '*does not match*'
        (Get-WMCachedBuild $cacheRoot).Manifest.SourceCommit | Should -Be $oldCommit
    }
    It 'reuses an identical artifact without overwriting its bytes' {
        Publish-WinUtilStableCache -CompiledPath $compiled -CacheRoot $cacheRoot -SourceCommit $newCommit -Locale $locale
        $path = (Get-WMCachedBuild $cacheRoot).ScriptPath
        $before = (Get-Item $path).LastWriteTimeUtc
        Publish-WinUtilStableCache -CompiledPath $compiled -CacheRoot $cacheRoot -SourceCommit $newCommit -Locale $locale
        (Get-WMCachedBuild $cacheRoot).ScriptPath | Should -Be $path
        (Get-Item $path).LastWriteTimeUtc | Should -Be $before
    }
    It 'rejects an invalid source commit before creating a cache' {
        { Publish-WinUtilStableCache -CompiledPath $compiled -CacheRoot $cacheRoot -SourceCommit 'invalid' -Locale $locale } | Should -Throw '*source commit*'
        Test-Path $cacheRoot | Should -BeFalse
    }
    It 'recovers the previous verified build when the active manifest is corrupt' {
        $old = New-TestLegacyCache $cacheRoot
        Publish-WinUtilStableCache -CompiledPath $compiled -CacheRoot $cacheRoot -SourceCommit $newCommit -Locale $locale
        [IO.File]::WriteAllText((Join-Path $cacheRoot 'release.json'), '{corrupt')
        (Get-WMCachedBuild $cacheRoot).ScriptPath | Should -Be $old
    }
    It 'recovers the previous build when the active script hash is wrong' {
        $old = New-TestLegacyCache $cacheRoot
        Publish-WinUtilStableCache -CompiledPath $compiled -CacheRoot $cacheRoot -SourceCommit $newCommit -Locale $locale
        [IO.File]::WriteAllText((Get-WMCachedBuild $cacheRoot).ScriptPath, 'bad hash')
        (Get-WMCachedBuild $cacheRoot).ScriptPath | Should -Be $old
    }
    It 'rejects a manifest artifact outside the cache root' {
        $null = New-TestLegacyCache $cacheRoot
        $manifest = Get-Content (Join-Path $cacheRoot 'release.json') -Raw | ConvertFrom-Json
        $manifest | Add-Member Artifact '../compiled.ps1'
        $manifest.Sha256 = (Get-FileHash $compiled -Algorithm SHA256).Hash
        $manifest | ConvertTo-Json | Set-Content (Join-Path $cacheRoot 'release.json')
        Get-WMCachedBuild $cacheRoot | Should -BeNullOrEmpty
    }
    It 'does not use an unverified legacy cache' {
        $old = New-TestLegacyCache $cacheRoot
        [IO.File]::WriteAllText($old, 'changed')
        Get-WMCachedBuild $cacheRoot | Should -BeNullOrEmpty
    }
}

Describe 'Bootstrap pinning and failed updates' {
    BeforeEach {
        Mock Invoke-WMStandalone {}
        Mock Invoke-WMUpdate {}
        Mock Get-WMSourceCommit { $newCommit }
    }
    It 'uses an already matching cache without downloading a launcher' {
        $old = New-TestLegacyCache $cacheRoot
        Mock Get-WMSourceCommit { $oldCommit }
        Invoke-WMSourceBootstrap -Branch 'russian'
        Should -Invoke Invoke-WMStandalone -Times 1 -ParameterFilter { $ScriptPath -eq $old }
        Should -Invoke Invoke-WMUpdate -Times 0
    }
    It 'uses the old verified cache when an update fails' {
        $old = New-TestLegacyCache $cacheRoot
        Mock Invoke-WMUpdate { throw 'update failed' }
        Invoke-WMSourceBootstrap -Branch 'russian'
        Should -Invoke Invoke-WMStandalone -Times 1 -ParameterFilter { $ScriptPath -eq $old }
        [IO.File]::ReadAllText($old) | Should -Be 'old verified build'
    }
    It 'keeps the pre-update script path even if a later error follows publication' {
        $old = New-TestLegacyCache $cacheRoot
        Mock Invoke-WMUpdate {
            Publish-WinUtilStableCache -CompiledPath $compiled -CacheRoot $cacheRoot -SourceCommit $newCommit -Locale $locale
            throw 'post-publication error'
        }
        Invoke-WMSourceBootstrap -Branch 'russian'
        Should -Invoke Invoke-WMStandalone -Times 1 -ParameterFilter { $ScriptPath -eq $old }
    }
    It 'starts only a verified cache when commit lookup is unavailable' {
        $old = New-TestLegacyCache $cacheRoot
        Mock Get-WMSourceCommit { throw 'offline' }
        Invoke-WMSourceBootstrap -Branch 'russian'
        Should -Invoke Invoke-WMStandalone -Times 1 -ParameterFilter { $ScriptPath -eq $old }
        Should -Invoke Invoke-WMUpdate -Times 0
    }
    It 'fails closed when offline and no verified cache exists' {
        Mock Get-WMSourceCommit { throw 'offline' }
        { Invoke-WMSourceBootstrap -Branch 'russian' } | Should -Throw '*offline*'
        Should -Invoke Invoke-WMUpdate -Times 0
        Should -Invoke Invoke-WMStandalone -Times 0
    }
}

Describe 'Commit-bound launcher download' {
    It 'downloads the launcher by exact SHA and restores the caller environment' {
        $env:WINUTIL_RU_COMMIT = $oldCommit
        Mock Get-WMRemoteText { '$script:observedCommit = $env:WINUTIL_RU_COMMIT' }
        Invoke-WMUpdate -Commit $newCommit
        $script:observedCommit | Should -Be $newCommit
        $env:WINUTIL_RU_COMMIT | Should -Be $oldCommit
        Should -Invoke Get-WMRemoteText -Times 1 -ParameterFilter { $Uri -eq "https://raw.githubusercontent.com/TokhirjonYuldoshev/WinUtil-RU/$newCommit/run-russian.ps1" }
    }
    It 'restores the commit environment after a failed download' {
        $env:WINUTIL_RU_COMMIT = $oldCommit
        Mock Get-WMRemoteText { throw 'download failure' }
        { Invoke-WMUpdate -Commit $newCommit } | Should -Throw '*download failure*'
        $env:WINUTIL_RU_COMMIT | Should -Be $oldCommit
    }
    It 'validates the SHA returned by GitHub' {
        Mock Get-WMRemoteText { '{"commit":{"sha":"invalid"}}' }
        { Get-WMSourceCommit -Branch 'russian' } | Should -Throw '*valid source commit*'
    }
}

Describe 'Pinned source launcher transaction' {
    BeforeAll {
        $originalTemp = $env:TEMP
        $originalBranch = $env:WINUTIL_RU_BRANCH
        $originalRestart = $env:WINDOWMANAGER_LAUNCHER_RESTART
        $originalExitCode = $global:LASTEXITCODE
        $script:sourceLauncher = Get-Content (Join-Path $repoRoot 'run-russian.ps1') -Raw -Encoding UTF8
        function pwsh.exe { param([switch]$NoProfile, $ExecutionPolicy, $File) }
        function powershell.exe { param([switch]$NoProfile, [switch]$STA, $ExecutionPolicy, $File, $CompiledScriptPath) }
    }
    AfterAll {
        $env:TEMP = $originalTemp
        $env:WINUTIL_RU_BRANCH = $originalBranch
        $env:WINDOWMANAGER_LAUNCHER_RESTART = $originalRestart
        $global:LASTEXITCODE = $originalExitCode
    }
    BeforeEach {
        $env:TEMP = $scenario
        $env:WINUTIL_RU_BRANCH = 'russian'
        $env:WINUTIL_RU_COMMIT = $newCommit
        $script:compileExit = 0; $script:wpfExit = 0; $script:appExit = 0
        $script:archiveUri = $null; $script:manifestAtLaunch = $null
        $old = New-TestLegacyCache $cacheRoot
        Mock Get-ItemProperty { [pscustomobject]@{ AppIconMode = 'Disabled'; RestartRequested = $false } }
        Mock Remove-ItemProperty {}
        Mock Invoke-WebRequest {
            $script:archiveUri = $Uri
            [IO.File]::WriteAllText($OutFile, 'fixture archive')
        }
        Mock Expand-Archive {
            $fixture = Join-Path $DestinationPath 'project'
            New-Item -ItemType Directory (Join-Path $fixture 'config') -Force | Out-Null
            [IO.File]::WriteAllText((Join-Path $fixture 'Compile.ps1'), 'exit 0')
            $locale | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $fixture 'config/localization_ru.json')
        }
        Mock pwsh.exe {
            if ($File -eq '.\Compile.ps1') {
                [IO.File]::WriteAllText((Join-Path $PWD 'winutil.ps1'), "Write-Output 'validated fixture'")
                $global:LASTEXITCODE = $script:compileExit
            } else {
                $script:manifestAtLaunch = (Get-Content (Join-Path $cacheRoot 'release.json') -Raw | ConvertFrom-Json).SourceCommit
                $global:LASTEXITCODE = $script:appExit
            }
        }
        Mock powershell.exe { $global:LASTEXITCODE = $script:wpfExit }
    }
    It 'downloads the pinned archive and publishes only after successful application exit' {
        & ([scriptblock]::Create($script:sourceLauncher))
        $script:archiveUri | Should -Be "https://github.com/TokhirjonYuldoshev/WinUtil-RU/archive/$newCommit.zip"
        $script:manifestAtLaunch | Should -Be $oldCommit
        (Get-WMCachedBuild $cacheRoot).Manifest.SourceCommit | Should -Be $newCommit
        [IO.File]::ReadAllText($old) | Should -Be 'old verified build'
    }
    It 'leaves the old pointer intact when compilation fails' {
        $script:compileExit = 1
        { & ([scriptblock]::Create($script:sourceLauncher)) } | Should -Throw '*Код завершения: 1*'
        (Get-WMCachedBuild $cacheRoot).Manifest.SourceCommit | Should -Be $oldCommit
        Should -Invoke powershell.exe -Times 0
    }
    It 'leaves the old pointer intact when WPF validation fails' {
        $script:wpfExit = 1
        { & ([scriptblock]::Create($script:sourceLauncher)) } | Should -Throw '*WPF validation*'
        (Get-WMCachedBuild $cacheRoot).Manifest.SourceCommit | Should -Be $oldCommit
        Should -Invoke pwsh.exe -Times 0 -ParameterFilter { $File -ne '.\Compile.ps1' }
    }
    It 'leaves the old pointer intact when the new application exits with an error' {
        $script:appExit = 1
        { & ([scriptblock]::Create($script:sourceLauncher)) } | Should -Throw '*завершился с кодом 1*'
        (Get-WMCachedBuild $cacheRoot).Manifest.SourceCommit | Should -Be $oldCommit
        [IO.File]::ReadAllText($old) | Should -Be 'old verified build'
    }
}

Describe 'Analyzer CI severity gate' {
    BeforeAll {
        function Invoke-ScriptAnalyzer {}
        $workflow = Get-Content (Join-Path $repoRoot '.github/workflows/unittests.yaml') -Raw
        $match = [regex]::Match($workflow, '(?s)- name: Run PSScriptAnalyzer\r?\n      run: \|\r?\n(?<body>.*?)      shell: pwsh')
        if (-not $match.Success) { throw 'Analyzer step was not found.' }
        $script:analyzerStep = [scriptblock]::Create(($match.Groups['body'].Value -replace '(?m)^        ', ''))
    }
    It 'blocks a severity Error diagnostic' {
        Mock Invoke-ScriptAnalyzer { [pscustomobject]@{ Severity = 'Error'; Message = 'test error' } }
        { & $script:analyzerStep } | Should -Throw '*severity Error*'
    }
    It 'prints accepted warnings without suppressing them or failing' {
        Mock Invoke-ScriptAnalyzer { [pscustomobject]@{ Severity = 'Warning'; Message = 'accepted warning' } }
        { & $script:analyzerStep } | Should -Not -Throw
        Should -Invoke Invoke-ScriptAnalyzer -Times 1
    }
}
}
