BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    . (Join-Path $repoRoot 'functions/private/Initialize-WinUtilRussianLocalization.ps1')
    $locale = Get-Content (Join-Path $repoRoot 'config/localization_ru.json') -Raw -Encoding UTF8 | ConvertFrom-Json

    $script:sync = @{
        preferences = @{}
        configs = @{
            localization_ru = $locale
        }
    }
    $script:inputXML = Get-Content (Join-Path $repoRoot 'xaml/inputXML.xaml') -Raw -Encoding UTF8
    Initialize-WinUtilRussianLocalization
}

Describe 'Russian presentation without changing internal keys' {
    It 'translates visible headings and multi-line ISO guidance' {
        $script:sync.preferences.language = 'ru-RU'
        Convert-WinUtilRussianText 'Essential Tweaks' | Should -Be 'Основные настройки'
        Convert-WinUtilRussianText "Step 1 - Select`n Windows 11 ISO" | Should -Be 'Шаг 1 — выберите ISO-образ Windows 11'
    }

    It 'returns the original English text when English is selected' {
        $script:sync.preferences.language = 'en-US'
        Convert-WinUtilRussianText 'Essential Tweaks' | Should -Be 'Essential Tweaks'
    }

    It 'keeps named controls while adding the two language options' {
        [xml]$localized = $script:inputXML
        $localized.SelectSingleNode("//*[@Name='WPFTab1BT']") | Should -Not -BeNullOrEmpty
        $localized.SelectSingleNode("//*[@Name='RussianLanguageMenuItem']") | Should -Not -BeNullOrEmpty
        $localized.SelectSingleNode("//*[@Name='EnglishLanguageMenuItem']") | Should -Not -BeNullOrEmpty
    }

    It 'shows Russian ISO placeholders without replacing the values read by the original handler' {
        $script:sync.preferences.language = 'ru-RU'
        [xml]$localized = $script:inputXML
        $localized.SelectSingleNode("//*[@Name='WPFWin11ISOPath']").GetAttribute('Text') | Should -Be 'No ISO selected...'
        $localized.SelectSingleNode("//*[@Name='WPFWin11ISOStatusLog']").GetAttribute('Text') | Should -Be 'Ready. Please select a Windows 11 ISO to begin.'
        $localized.SelectNodes("//*[local-name()='DataTrigger' and @Value='No ISO selected...']").Count | Should -Be 1
        $localized.SelectNodes("//*[local-name()='DataTrigger' and @Value='Ready. Please select a Windows 11 ISO to begin.']").Count | Should -Be 1
        Convert-WinUtilRussianText 'Tweaks finished' | Should -Be 'Настройки применены'
    }
}
