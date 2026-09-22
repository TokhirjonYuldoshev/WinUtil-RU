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

    $localizedDescription = Convert-WinUtilRussianText $Description
    $keyLabel = if ($sync.preferences.language -eq 'ru-RU') { 'Ключ пресета' } else { 'Preset key' }

    if ([string]::IsNullOrWhiteSpace($localizedDescription)) {
        return "${keyLabel}: $Key"
    }

    return "$localizedDescription`n`n${keyLabel}: $Key"
}
