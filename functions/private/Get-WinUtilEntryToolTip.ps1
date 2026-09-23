function Get-WinUtilEntryToolTip {
    <#
        .SYNOPSIS
            Builds the tooltip string for an app/tweak/feature entry: its description plus its preset JSON key

        .PARAMETER Description
            The entry's description from the config JSON. May be null or empty.

        .PARAMETER Key
            The entry's JSON key as used in preset files (e.g. WPFInstallbrave, WPFTweaksTele).
    #>
    param(
        [Parameter(Mandatory = $false)]
        [string]$Description,

        [Parameter(Mandatory = $true)]
        [string]$Key
    )

    $localizedDescription = $Description
    if (Get-Command Convert-WinUtilRussianText -ErrorAction SilentlyContinue) {
        $localizedDescription = Convert-WinUtilRussianText $Description
    }

    $isRussian = $false
    $syncVariable = Get-Variable -Name sync -ErrorAction SilentlyContinue
    if ($null -ne $syncVariable -and $null -ne $syncVariable.Value.preferences) {
        $isRussian = $syncVariable.Value.preferences.language -eq 'ru-RU'
    }
    $keyLabel = if ($isRussian) { 'Ключ пресета' } else { 'Preset key' }

    if ([string]::IsNullOrWhiteSpace($localizedDescription)) {
        return "${keyLabel}: $Key"
    }

    return "$localizedDescription`n`n${keyLabel}: $Key"
}
