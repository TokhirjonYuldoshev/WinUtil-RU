#===========================================================================
# Russian localization regression tests
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $script:localizationPath = Join-Path $script:repoRoot "functions\private\Initialize-WinUtilRussianLocalization.ps1"
    $script:appEntryPath = Join-Path $script:repoRoot "functions\private\Initialize-InstallAppEntry.ps1"
    $script:xamlPath = Join-Path $script:repoRoot "xaml\inputXML.xaml"
    $script:applicationsPath = Join-Path $script:repoRoot "config\applications.json"
    $script:applicationsRuPath = Join-Path $script:repoRoot "config\applications_ru.json"
}

Describe "Russian localization source" {
    It "parses as PowerShell" {
        $tokens = $null
        $errors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile(
            $script:localizationPath,
            [ref]$tokens,
            [ref]$errors
        )

        @($errors) | Should -HaveCount 0
    }

    It "has no case-insensitive duplicate exact translation keys" {
        $text = Get-Content -LiteralPath $script:localizationPath -Raw -Encoding UTF8
        $exactBlock = [regex]::Match(
            $text,
            '(?s)\$sync\.WinUtilRussianExactTranslations\s*=\s*@\{(?<body>.*?)\r?\n\s*\}\r?\n\r?\n\s*\$sync\.WinUtilRussianPhraseTranslations'
        ).Groups['body'].Value

        $keys = @(
            [regex]::Matches($exactBlock, "(?m)^\s*'((?:''|[^'])*)'\s*=") |
                ForEach-Object { $_.Groups[1].Value -replace "''", "'" }
        )

        $duplicates = @(
            $keys |
                Group-Object { $_.ToLowerInvariant() } |
                Where-Object Count -gt 1 |
                ForEach-Object Name
        )

        $duplicates | Should -BeNullOrEmpty
    }

    It "keeps core tab headers as stable English logic keys" {
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
        $russian = $xaml.SelectSingleNode("//*[local-name()='MenuItem'][@Name='RussianLanguageMenuItem']")
        $english = $xaml.SelectSingleNode("//*[local-name()='MenuItem'][@Name='EnglishLanguageMenuItem']")
        $wrapper = $xaml.SelectSingleNode("//*[@Name='LanguageMenuItem']")

        $russian | Should -Not -BeNullOrEmpty
        $english | Should -Not -BeNullOrEmpty
        $wrapper | Should -BeNullOrEmpty
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

Describe "Install localization safety" {
    It "does not use the unsupported ImageOpened event on WPF Image" {
        $text = Get-Content -LiteralPath $script:appEntryPath -Raw -Encoding UTF8
        $text | Should -Not -Match 'Add_ImageOpened'
    }

    It "uses the raw catalog key for the persistent icon cache" {
        $text = Get-Content -LiteralPath $script:appEntryPath -Raw -Encoding UTF8
        $text | Should -Match "\$catalogKey\s*=\s*\$appKey\s*-replace\s*'\^WPFInstall'"
        $text | Should -Match "\$safeIconName\s*=\s*\(\$catalogKey\s*-replace"
    }
}
