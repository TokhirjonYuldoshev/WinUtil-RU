# Installs the exact CI Pester version in the Windows PowerShell 5.1 module scope.
# PowerShell 7 and Windows PowerShell 5.1 use different CurrentUser module paths.
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$requiredVersion = [version]'5.8.0'

if ($PSVersionTable.PSVersion.Major -ne 5 -or $PSVersionTable.PSVersion.Minor -ne 1) {
    throw 'The pinned Pester 5.1 bootstrap must run in Windows PowerShell 5.1.'
}

# Windows PowerShell 5.1 may otherwise negotiate an unsupported TLS version.
[Net.ServicePointManager]::SecurityProtocol = (
    [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
)

$module = Get-Module -ListAvailable -Name Pester |
    Where-Object { $_.Version -eq $requiredVersion } |
    Select-Object -First 1

if (-not $module) {
    # Initialize NuGet and PSGallery inside PS5.1, not the earlier pwsh step.
    $nuget = Get-PackageProvider -ListAvailable -Name NuGet -ErrorAction SilentlyContinue |
        Where-Object { $_.Version -ge [version]'2.8.5.201' } |
        Select-Object -First 1
    if (-not $nuget) {
        Install-PackageProvider -Name NuGet -MinimumVersion '2.8.5.201' -Scope CurrentUser -Force -ErrorAction Stop | Out-Null
    }
    if (-not (Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue)) {
        Register-PSRepository -Default -ErrorAction Stop
    }
    Install-Module -Name Pester -RequiredVersion $requiredVersion.ToString() -Repository PSGallery -Scope CurrentUser -Force -SkipPublisherCheck -ErrorAction Stop
}

Import-Module Pester -RequiredVersion $requiredVersion.ToString() -Force -ErrorAction Stop
$loaded = Get-Module Pester
if (-not $loaded -or $loaded.Version -ne $requiredVersion) {
    throw "Pester version mismatch under Windows PowerShell 5.1: expected $requiredVersion."
}
Write-Host "Windows PowerShell $($PSVersionTable.PSVersion): imported Pester $($loaded.Version) from $($loaded.Path)"
