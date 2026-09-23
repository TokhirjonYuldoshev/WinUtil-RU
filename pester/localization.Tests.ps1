#===========================================================================
# Russian edition regression tests
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $script:localizationPath = Join-Path $script:repoRoot "functions\private\Initialize-WinUtilRussianLocalization.ps1"
    $script:runtimeLocalizationPath = Join-Path $script:repoRoot "functions\private\Convert-WinUtilRussianRuntimeText.ps1"
    $script:appEntryPath = Join-Path $script:repoRoot "functions\private\Initialize-InstallAppEntry.ps1"
    $script:stepPath = Join-Path $script:repoRoot "functions\private\Step-WinUtilJob.ps1"
    $script:messagePath = Join-Path $script:repoRoot "functions\private\Show-WinUtilMessage.ps1"
    $script:isoPath = Join-Path $script:repoRoot "functions\private\Invoke-WinUtilISO.ps1"
    $script:xamlPath = Join-Path $script:repoRoot "xaml\inputXML.xaml"
    $script:applicationsPath = Join-Path $script:repoRoot "config\applications.json"
    $script:applicationsRuPath = Join-Path $script:repoRoot "config\applications_ru.json"
    $script:localePath = Join-Path $script:repoRoot "config\localization_ru.json"
    $script:launcherPath = Join-Path $script:repoRoot "run-russian.ps1"
    $script:preflightPath = Join-Path $script:repoRoot "tools\Test-WinUtilRussianEdition.ps1"

    function script:Assert-WinUtilPowerShellParses {
        param([string]$Path)

        $tokens = $null
        $errors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile(
            $Path,
            [ref]$tokens,
            [ref]$errors
        )
        @($errors) | Should -HaveCount 0 -Because "$Path must parse before the Russian edition can launch"
    }
}

Describe "Russian localization engine" {
    It "parses the localization, runtime and preflight scripts" {
        Assert-WinUtilPowerShellParses $script:localizationPath
        Assert-WinUtilPowerShellParses $script:runtimeLocalizationPath
        Assert-WinUtilPowerShellParses $script:preflightPath
    }

    It "loads translations from locale data instead of a giant PowerShell literal" {
        $source = Get-Content -LiteralPath $script:localizationPath -Raw -Encoding UTF8

        $source | Should -Match '\$sync\.configs\.localization_ru'
        $source | Should -Not -Match "'Change the WinUtil UI Theme'\s*="
        (Get-Content -LiteralPath $script:localizationPath).Count | Should -BeLessThan 300
    }

    It "keeps static and dynamic translation concerns separated" {
        $runtimeSource = Get-Content -LiteralPath $script:runtimeLocalizationPath -Raw -Encoding UTF8
        $messageSource = Get-Content -LiteralPath $script:messagePath -Raw -Encoding UTF8
        $stepSource = Get-Content -LiteralPath $script:stepPath -Raw -Encoding UTF8

        $runtimeSource | Should -Match 'function Convert-WinUtilRussianRuntimeText'
        $messageSource | Should -Match 'Convert-WinUtilRussianRuntimeText'
        $stepSource | Should -Match 'Convert-WinUtilRussianRuntimeText'
        (Get-Content -LiteralPath $script:runtimeLocalizationPath).Count | Should -BeLessThan 250
    }

    It "has a valid and complete Russian locale file" {
        $locale = Get-Content -LiteralPath $script:localePath -Raw -Encoding UTF8 | ConvertFrom-Json

        $locale.Meta.Language | Should -Be 'ru-RU'
        $locale.Meta.Fallback | Should -Be 'en-US'
        $locale.Meta.Version | Should -Match '^\d+\.\d+\.\d+$'
        @($locale.Exact.PSObject.Properties).Count | Should -BeGreaterThan 450
        @($locale.Phrases).Count | Should -BeGreaterThan 10
        @($locale.Navigation.PSObject.Properties).Count | Should -Be 5
        @($locale.Win11StepHeaders.PSObject.Properties).Count | Should -Be 3

        $blankExact = @(
            $locale.Exact.PSObject.Properties |
                Where-Object {
                    [string]::IsNullOrWhiteSpace([string]$_.Name) -or
                    [string]::IsNullOrWhiteSpace([string]$_.Value)
                }
        )
        $blankPhrases = @(
            $locale.Phrases |
                Where-Object {
                    [string]::IsNullOrWhiteSpace([string]$_.Source) -or
                    [string]::IsNullOrWhiteSpace([string]$_.Target)
                }
        )

        $blankExact | Should -BeNullOrEmpty
        $blankPhrases | Should -BeNullOrEmpty
    }
}

Describe "Russian UI safety" {
    It "keeps core tab headers as stable English routing keys" {
        [xml]$xaml = Get-Content -LiteralPath $script:xamlPath -Raw -Encoding UTF8
        $expected = @{
            WPFTab1 = 'Install'
            WPFTab2 = 'Tweaks'
            WPFTab3 = 'Config'
            WPFTab4 = 'Updates'
            WPFTab5 = 'Win11ISO'
            WPFTab6 = 'AppX'
        }

        foreach ($name in $expected.Keys) {
            $node = $xaml.SelectSingleNode("//*[local-name()='TabItem'][@Name='$name']")
            $node | Should -Not -BeNullOrEmpty
            $node.GetAttribute('Header') | Should -Be $expected[$name]
        }
    }

    It "exposes Russian and English directly in Settings" {
        [xml]$xaml = Get-Content -LiteralPath $script:xamlPath -Raw -Encoding UTF8

        $xaml.SelectSingleNode("//*[local-name()='MenuItem'][@Name='RussianLanguageMenuItem']") | Should -Not -BeNullOrEmpty
        $xaml.SelectSingleNode("//*[local-name()='MenuItem'][@Name='EnglishLanguageMenuItem']") | Should -Not -BeNullOrEmpty
        $xaml.SelectSingleNode("//*[@Name='LanguageMenuItem']") | Should -BeNullOrEmpty
    }

    It "keeps Win11 Creator sentinel values in English for internal state checks" {
        $isoSource = Get-Content -LiteralPath $script:isoPath -Raw -Encoding UTF8

        $isoSource | Should -Match '\$box\.Text -eq "Ready\. Please select a Windows 11 ISO to begin\."'
        $isoSource | Should -Match '\$isoPath -eq "No ISO selected\.\.\."'
    }
}

Describe "Russian application catalog" {
    It "matches every application key exactly" {
        $applications = Get-Content -LiteralPath $script:applicationsPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $russian = Get-Content -LiteralPath $script:applicationsRuPath -Raw -Encoding UTF8 | ConvertFrom-Json

        $sourceKeys = @($applications.PSObject.Properties.Name | Sort-Object)
        $russianKeys = @($russian.PSObject.Properties.Name | Sort-Object)

        Compare-Object $sourceKeys $russianKeys | Should -BeNullOrEmpty
    }

    It "contains a non-empty Russian description for every application" {
        $russian = Get-Content -LiteralPath $script:applicationsRuPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $missing = @(
            $russian.PSObject.Properties |
                Where-Object { [string]::IsNullOrWhiteSpace([string]$_.Value) } |
                ForEach-Object Name
        )

        $missing | Should -BeNullOrEmpty
    }
}

Describe "Install tab regression guards" {
    It "does not use the unsupported ImageOpened event on WPF Image" {
        $text = Get-Content -LiteralPath $script:appEntryPath -Raw -Encoding UTF8
        $text | Should -Not -Match 'Add_ImageOpened'
    }

    It "uses the raw catalog key for the persistent icon cache" {
        $text = Get-Content -LiteralPath $script:appEntryPath -Raw -Encoding UTF8

        $text | Should -Match '\$catalogKey\s*=\s*\$appKey\s*-replace\s*''\^WPFInstall'''
        $text | Should -Match '\$safeIconName\s*=\s*\(\$catalogKey\s*-replace'
    }
}

Describe "Online Russian launcher" {
    It "supports stable and dev channels and validates before compile" {
        $launcher = Get-Content -LiteralPath $script:launcherPath -Raw -Encoding UTF8

        $launcher | Should -Match "WINDOWMANAGER_BRANCH"
        $launcher | Should -Match "'russian-dev'"
        $launcher | Should -Match 'Test-WinUtilRussianEdition\.ps1'
        $launcher | Should -Match 'Compile\.ps1'
    }

    It "supports in-place restart after changing language" {
        $launcher = Get-Content -LiteralPath $script:launcherPath -Raw -Encoding UTF8

        $launcher | Should -Match 'WINDOWMANAGER_LAUNCHER_RESTART'
        $launcher | Should -Match 'RestartRequested'
        $launcher | Should -Match 'do\s*\{'
    }
}
