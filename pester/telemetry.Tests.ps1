BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $config = Get-Content -Path (Join-Path $repoRoot 'config/tweaks.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $telemetry = $config.WPFTweaksTelemetry
    $script:applyDefender = [scriptblock]::Create(($telemetry.InvokeScript[0] -split '# Disable \(Connected User Experiences and Telemetry\) Service')[0])
    $script:undoDefender = [scriptblock]::Create(($telemetry.UndoScript[0] -split '# Enable \(Connected User Experiences and Telemetry\) Service')[0])

    function Set-MpPreference { param($SubmitSamplesConsent) }
    function Convert-WinUtilRussianText { param($Value) $Value }
}

Describe 'Telemetry tweak Defender setting' {
    BeforeEach {
        Mock Get-Service { [pscustomobject]@{ Status = 'Stopped' } }
        Mock Set-MpPreference {}
        Mock Write-Warning {}
    }

    It 'skips the apply setting and warns if Defender is stopped' {
        & $script:applyDefender

        Should -Invoke Set-MpPreference -Times 0 -Exactly
        Should -Invoke Write-Warning -Times 1 -Exactly
    }

    It 'skips the undo setting and warns if Defender is stopped' {
        & $script:undoDefender

        Should -Invoke Set-MpPreference -Times 0 -Exactly
        Should -Invoke Write-Warning -Times 1 -Exactly
    }

    It 'still applies the original Defender preference when the service is running' {
        Mock Get-Service { [pscustomobject]@{ Status = 'Running' } }

        & $script:applyDefender

        Should -Invoke Set-MpPreference -Times 1 -Exactly -ParameterFilter { $SubmitSamplesConsent -eq 2 }
        Should -Invoke Write-Warning -Times 0 -Exactly
    }

    It 'still restores the original Defender preference when the service is running' {
        Mock Get-Service { [pscustomobject]@{ Status = 'Running' } }

        & $script:undoDefender

        Should -Invoke Set-MpPreference -Times 1 -Exactly -ParameterFilter { $SubmitSamplesConsent -eq 1 }
        Should -Invoke Write-Warning -Times 0 -Exactly
    }
}
