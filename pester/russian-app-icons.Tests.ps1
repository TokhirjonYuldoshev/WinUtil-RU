BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    . (Join-Path $repoRoot 'functions/private/Get-WinUtilAppIconSource.ps1')
    $catalog = Get-Content (Join-Path $repoRoot 'config/application_icons.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $applications = Get-Content (Join-Path $repoRoot 'config/applications.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) {
        Add-Type -AssemblyName PresentationCore
    }
    $oldLocalAppData = $env:LOCALAPPDATA
}
AfterAll { $env:LOCALAPPDATA = $oldLocalAppData }
Describe 'Russian app icon display sources' {
    BeforeEach {
        $env:LOCALAPPDATA = $TestDrive
        $script:sync = @{ WinUtilAppIconMode = 'Auto'; configs = @{} }
    }
    It 'contains the reported missing apps, original application keys and PNG data' {
        foreach ($key in @('ungoogled', 'ZenBrowser', 'qtox', 'thunderbird', 'okular', 'onlyoffice',
                'cemu', 'ubisoft', 'glazewm', 'peazip', 'protonauth', 'protondrive', 'Zed',
                'terminal', 'eartrumpet', 'gimp', 'klite', 'totalcommander', 'vlc', 'blurautoclicker')) {
            $applications.PSObject.Properties[$key] | Should -Not -BeNullOrEmpty
            $entry = $catalog.Icons.PSObject.Properties[$key].Value
            $bytes = [Convert]::FromBase64String($entry.PngBase64)
            [BitConverter]::ToString($bytes, 0, 8) | Should -Be '89-50-4E-47-0D-0A-1A-0A'
            $entry.Source | Should -Match '^https://(github\.com/|www\.ghisler\.com/favicon\.ico$|codecguide\.com/mpc_logo\.png$)'
        }
    }
    It 'uses the original native asynchronous URL for an uncached app in Auto mode' {
        Get-WinUtilAppIconSource -AppKey WPFInstalltest -Link 'https://example.org/path' |
            Should -Be 'https://www.google.com/s2/favicons?sz=64&domain_url=https%3A%2F%2Fexample.org%2Fpath'
    }
    It 'does not return a network source in CacheOnly mode' {
        $script:sync.WinUtilAppIconMode = 'CacheOnly'
        Get-WinUtilAppIconSource -AppKey WPFInstalltest -Link 'https://example.org/' | Should -BeNullOrEmpty
    }
    It 'disables both built-in and remote images in Disabled mode' {
        $script:sync.WinUtilAppIconMode = 'Disabled'
        $script:sync.configs.application_icons = $catalog
        Get-WinUtilAppIconSource -AppKey WPFInstallZenBrowser -Link 'https://example.org/' | Should -BeNullOrEmpty
    }
    It 'decodes every bundled PNG without network access in CacheOnly mode' -Skip:([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
        $script:sync.WinUtilAppIconMode = 'CacheOnly'
        $script:sync.configs.application_icons = $catalog
        foreach ($entry in $catalog.Icons.PSObject.Properties) {
            $image = Get-WinUtilAppIconSource -AppKey ('WPFInstall' + $entry.Name) -Link 'https://example.org/'
            $image | Should -BeOfType ([Windows.Media.Imaging.BitmapImage])
            $image.IsFrozen | Should -BeTrue
            $image.PixelWidth | Should -BeGreaterThan 0
            $image.PixelHeight | Should -BeGreaterThan 0
        }
    }
    It 'loads a valid cached image and releases the file handle' -Skip:([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
        $script:sync.WinUtilAppIconMode = 'CacheOnly'
        $folder = Join-Path $TestDrive 'YTY/WindowManager/IconCache'
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
        $path = Join-Path $folder 'test.png'
        [IO.File]::WriteAllBytes($path, [Convert]::FromBase64String($catalog.Icons.ZenBrowser.PngBase64))
        $image = Get-WinUtilAppIconSource -AppKey WPFInstalltest -Link 'https://example.org/'
        $image | Should -BeOfType ([Windows.Media.Imaging.BitmapImage])
        $image.IsFrozen | Should -BeTrue
        { Remove-Item -LiteralPath $path -ErrorAction Stop } | Should -Not -Throw
    }
    It 'falls back from corrupt cache to native WPF in Auto and to no image in CacheOnly' {
        $folder = Join-Path $TestDrive 'YTY/WindowManager/IconCache'
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $folder 'broken.png'), '<html>blocked</html>')
        Get-WinUtilAppIconSource -AppKey WPFInstallbroken -Link 'https://example.org/' | Should -BeLike 'https://www.google.com/s2/favicons?*'
        $script:sync.WinUtilAppIconMode = 'CacheOnly'
        Get-WinUtilAppIconSource -AppKey WPFInstallbroken -Link 'https://example.org/' | Should -BeNullOrEmpty
    }
}
