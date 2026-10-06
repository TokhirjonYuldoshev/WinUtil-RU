BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    . (Join-Path $repoRoot 'functions/private/Initialize-WinUtilRussianLocalization.ps1')
    . (Join-Path $repoRoot 'functions/private/New-WinUtilSessionState.ps1')
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

    It 'keeps each localized Border at one visual child' {
        [xml]$localized = $script:inputXML
        foreach ($border in $localized.SelectNodes("//*[local-name()='Border']")) {
            $children = @($border.ChildNodes | Where-Object {
                $_.NodeType -eq [System.Xml.XmlNodeType]::Element -and $_.LocalName -notlike '*.*'
            })
            $children.Count | Should -BeLessOrEqual 1
        }
        $status = $localized.SelectSingleNode("//*[@Name='WPFWin11ISOStatusLog']")
        $status.ParentNode.LocalName | Should -Be 'Grid'
        $status.ParentNode.ParentNode.LocalName | Should -Be 'Border'
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

Describe '26.09.29 interface-thread localization' {
    It 'copies the translation function and chosen language into the upstream session state' {
        $script:sync.preferences.language = 'ru-RU'
        $state = New-WinUtilSessionState
        $worker = [powershell]::Create($state)
        try {
            [void]$worker.AddScript("Convert-WinUtilRussianText 'Essential Tweaks'")
            $result = $worker.Invoke()
            $worker.Streams.Error.Count | Should -Be 0
            $result[0] | Should -Be 'Основные настройки'
        } finally {
            $worker.Dispose()
        }
    }

    It 'preserves the internal Fastest DNS value while translating its display text' {
        $script:sync.preferences.language = 'ru-RU'
        Convert-WinUtilRussianText 'Fastest' | Should -Be 'Самый быстрый'
        $dnsSource = Get-Content (Join-Path $PSScriptRoot '../functions/private/Set-WinUtilDNS.ps1') -Raw
        $dnsSource | Should -Match ([regex]::Escape('$DNSProvider -eq "Fastest"'))
    }
}
