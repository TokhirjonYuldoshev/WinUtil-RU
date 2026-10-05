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

    $keyLabel = 'Preset key'
    if ($null -ne $sync -and $sync.preferences.language -eq 'ru-RU') {
        $Description = Convert-WinUtilRussianText $Description
        $keyLabel = 'Ключ пресета'
    }

    if ([string]::IsNullOrWhiteSpace($Description)) {
        return "${keyLabel}: $Key"
    }

    return "$Description`n`n${keyLabel}: $Key"
}
