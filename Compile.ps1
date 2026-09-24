param (
    [switch]$Run
)

$OFS = "`r`n"

# Variable to sync between runspaces
$sync = [Hashtable]::Synchronized(@{})
$sync.configs = @{}

$ruLocale = Get-Content -Path config\localization_ru.json -Raw -Encoding UTF8 | ConvertFrom-Json
$buildVersion = [string]$ruLocale.Meta.Version
$script = (Get-Content -Path scripts\start.ps1 -Encoding UTF8) -replace '#{replaceme}', $buildVersion

$script += Get-ChildItem -Path functions -Recurse -File | ForEach-Object {
    Get-Content -Path $_.FullName -Raw -Encoding UTF8
}

Get-ChildItem config | ForEach-Object {
    $obj = Get-Content -Path $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json

    if ($_.Name -eq "applications.json") {
        $fixed = [ordered]@{}
        foreach ($p in $obj.PSObject.Properties) {
            $fixed["WPFInstall$($p.Name)"] = $p.Value
        }
        $obj = [pscustomobject]$fixed
    }

    $json = $obj | ConvertTo-Json -Depth 10

    $sync.configs[$_.BaseName] = $obj
    $script += "`$sync.configs.$($_.BaseName) = @'`r`n$json`r`n'@ | ConvertFrom-Json"
}

$xaml = Get-Content -Path xaml\inputXML.xaml -Raw -Encoding UTF8
$script += "`$inputXML = @'`r`n$xaml`r`n'@"
$script += "`r`n`$script:inputXML = `$inputXML`r`nInitialize-WinUtilRussianLocalization`r`n`$inputXML = `$script:inputXML`r`n"

$autounattendXml = Get-Content -Path tools\autounattend.xml -Raw -Encoding UTF8
$script += "`$WinUtilAutounattendXml = @'`r`n$autounattendXml`r`n'@"

$script += Get-Content -Path scripts\main.ps1 -Raw -Encoding UTF8

$utf8Bom = New-Object System.Text.UTF8Encoding($true)
[System.IO.File]::WriteAllText((Join-Path $PWD 'winutil.ps1'), [string]$script, $utf8Bom)

if ($Run) {
    .\Winutil.ps1
}
