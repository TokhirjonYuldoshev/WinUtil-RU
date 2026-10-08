# Read-only icon diagnostics. ASCII/no BOM: safe for Windows PowerShell 5.1 irm | iex.
function Get-WinUtilRussianIconDiagnostic {
    param(
        [System.Collections.IDictionary]$Links = [ordered]@{
            chrome = 'https://www.google.com/chrome/'
            firefox = 'https://www.mozilla.org/firefox/'
            telegram = 'https://desktop.telegram.org/'
        },
        [string]$CacheRoot = (Join-Path $env:LOCALAPPDATA 'YTY/WindowManager/IconCache')
    )
    $mode = 'Auto'
    $modeSource = 'Default'
    try {
        $saved = (Get-ItemProperty -Path 'HKCU:\Software\YTY\WindowManager' -Name AppIconMode -ErrorAction Stop).AppIconMode
        if ($saved -in @('Auto', 'CacheOnly', 'Disabled')) { $mode = $saved; $modeSource = 'Saved' }
    } catch { }
    $cachedCount = @(Get-ChildItem -LiteralPath $CacheRoot -Filter '*.png' -File -ErrorAction SilentlyContinue).Count
    $previousTls = [Net.ServicePointManager]::SecurityProtocol
    try {
        [Net.ServicePointManager]::SecurityProtocol = $previousTls -bor [Net.SecurityProtocolType]::Tls12
        $checks = foreach ($key in $Links.Keys) {
            $uri = 'https://www.google.com/s2/favicons?sz=64&domain_url=' + [uri]::EscapeDataString([string]$Links[$key])
            $clock = [Diagnostics.Stopwatch]::StartNew()
            $status = $null; $contentType = $null; $signature = $null; $errorType = $null
            try {
                $response = Invoke-WebRequest -Uri $uri -UseBasicParsing -TimeoutSec 8 -ErrorAction Stop
                $status = [int]$response.StatusCode
                $contentType = [string]$response.Headers['Content-Type']
                $stream = $response.RawContentStream
                if ($stream.CanSeek) { $stream.Position = 0 }
                $header = New-Object byte[] 8
                $read = $stream.Read($header, 0, $header.Length)
                $magic = [BitConverter]::ToString($header, 0, $read)
                $signature = if ($magic -eq '89-50-4E-47-0D-0A-1A-0A') { 'PNG' }
                    elseif ($magic -like '00-00-01-00-*') { 'ICO' }
                    elseif ($magic -like 'FF-D8-FF-*') { 'JPEG' }
                    elseif ($magic -like '47-49-46-38-*') { 'GIF' }
                    else { 'Unrecognized' }
            } catch {
                $errorType = $_.Exception.GetType().Name
                $responseProperty = $_.Exception.PSObject.Properties['Response']
                if ($null -ne $responseProperty -and $null -ne $responseProperty.Value) { $status = [int]$responseProperty.Value.StatusCode }
            }
            $clock.Stop()
            [pscustomobject]@{
                App = [string]$key
                CachedFileExists = Test-Path -LiteralPath (Join-Path $CacheRoot (($key -replace '[^A-Za-z0-9_.-]', '_') + '.png')) -PathType Leaf
                HttpStatus = $status
                ContentType = $contentType
                ImageSignature = $signature
                ElapsedMs = $clock.ElapsedMilliseconds
                ErrorType = $errorType
            }
        }
    } finally { [Net.ServicePointManager]::SecurityProtocol = $previousTls }
    [pscustomobject]@{
        SavedWarmupMode = $mode
        ModeSource = $modeSource
        CachedPngCount = $cachedCount
        # The current app-entry renderer loads Google URLs directly, not this cache.
        WpfUsesWarmupCache = $false
        Note = 'HTTP image success does not prove WPF Image.Source loaded successfully. Explicit diagnostics check the network even in CacheOnly/Disabled mode.'
        Checks = @($checks)
    }
}

Get-WinUtilRussianIconDiagnostic | ConvertTo-Json -Depth 5
