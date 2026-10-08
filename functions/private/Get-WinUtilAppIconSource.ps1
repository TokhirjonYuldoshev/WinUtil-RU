function Get-WinUtilAppIconSource {
    <#
    .SYNOPSIS
        Resolves display-only app icons without blocking the interface on downloads.
    #>
    param([string]$AppKey, [string]$Link)

    $mode = $sync.WinUtilAppIconMode
    if ($mode -eq 'Disabled') { return $null }
    $catalogKey = $AppKey -replace '^WPFInstall', ''
    $sources = @()
    $cachePath = $null
    if ($null -ne $sync.configs.application_icons) {
        $entry = $sync.configs.application_icons.Icons.PSObject.Properties[$catalogKey]
        if ($null -ne $entry) { $sources += [string]$entry.Value.PngBase64 }
    }

    # OnLoad releases the file before the warmup worker replaces it or cache is cleared.
    if (-not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
        $cacheName = ($catalogKey -replace '[^A-Za-z0-9_.-]', '_') + '.png'
        $cachePath = Join-Path $env:LOCALAPPDATA ('YTY/WindowManager/IconCache/' + $cacheName)
        if (Test-Path -LiteralPath $cachePath -PathType Leaf) { $sources += $cachePath }
    }
    foreach ($source in $sources) {
        $stream = $null
        try {
            $bytes = if ($source -eq $cachePath) { [IO.File]::ReadAllBytes($source) }
                else { [Convert]::FromBase64String($source) }
            $stream = [IO.MemoryStream]::new([byte[]]$bytes)
            $bitmap = New-Object Windows.Media.Imaging.BitmapImage
            $bitmap.BeginInit()
            $bitmap.CacheOption = [Windows.Media.Imaging.BitmapCacheOption]::OnLoad
            $bitmap.StreamSource = $stream
            $bitmap.EndInit()
            $bitmap.Freeze()
            return $bitmap
        } catch {
            # Corrupt or inaccessible local data must not prevent rendering the app entry.
        } finally {
            if ($null -ne $stream) { $stream.Dispose() }
        }
    }

    if ($mode -ne 'CacheOnly' -and -not [string]::IsNullOrWhiteSpace($Link)) {
        # Keep native WPF downloads overlapped with rendering, as in the original UI.
        return "https://www.google.com/s2/favicons?sz=64&domain_url=$([uri]::EscapeDataString($Link))"
    }
    return $null
}
