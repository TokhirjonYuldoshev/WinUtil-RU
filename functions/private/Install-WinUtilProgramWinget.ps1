Function Install-WinUtilProgramWinget {
    <#

    .SYNOPSIS
        Installs or uninstalls packages with WinGet and reports the outcome of each one

    .DESCRIPTION
        Emits one result object per package so the caller can tell what actually happened
        rather than assuming the run succeeded.

        Runs one winget command per package so a failure names the package that failed rather
        than the whole batch. Progress moves per package: winget hides its own progress bar once
        its output is redirected, so there is nothing to report from inside a single install.

    #>
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("Install", "Uninstall", "Upgrade")]
        [string]$Action,

        [Parameter(Mandatory=$true)]
        [string[]]$Programs
    )

    # APPINSTALLER_CLI_ERROR_ADMIN_CONTEXT_ACTION_PROHIBITED. WinGet refuses to act on a package
    # that was installed in user scope while it is running elevated, and WinUtil is always
    # elevated, so every per-user app answers this and nothing happens.
    $adminContextProhibited = -1978335107

    # WinGet reports "there was nothing to do" through the exit code rather than as success
    $nothingToDo = @{
        -1978335135 = "already installed"
        -1978335189 = "no applicable update"
    }
    # The installer worked and wants a restart to finish. Windows reports that as its own exit
    # code rather than as zero, and treating it as a failure marks working installs as broken.
    $rebootExitCodes = @{
        3010 = "installed, a restart is needed to finish"
        1641 = "installed, the installer started a restart"
        # WinGet's own equivalents. -1978334966 is deliberately absent: it means a reboot is
        # required before the install can proceed, which is not a completed install.
        -1978334967 = "installed, a restart is needed to finish"
        -1978334965 = "installed, the installer started a restart"
    }

    # Some WinGet failures surface raw Windows networking HRESULTs instead of WinGet-specific
    # return codes. Keep the diagnostic text in English for the log; the Russian presentation
    # layer translates it only when it is shown to the user.
    $knownFailureDetails = @{
        "80072EFD" = "WinGet could not connect to a package source (0x80072EFD). Check the Internet connection, proxy, VPN, firewall, or source availability, then try again."
        "80072EFE" = "The connection to a package source was interrupted (0x80072EFE). Check the Internet connection, proxy, VPN, firewall, or TLS/network filtering, then try again."
        "80D02002" = "The package source request timed out (0x80D02002). Check the Internet connection, proxy, VPN, firewall, or source availability, then try again."
    }
    $transientNetworkExitCodes = @("80072EFD", "80072EFE", "80D02002")

    foreach ($program in $Programs) {
        if ([string]::IsNullOrWhiteSpace($program) -or $program -eq "na") {
            continue
        }

        $upgradeAll = $Action -eq "Upgrade" -and $program -eq "all"
        $source = if ($upgradeAll) { "all configured sources" } else { "winget" }
        if (-not $upgradeAll -and $program.StartsWith("msstore:", [System.StringComparison]::OrdinalIgnoreCase)) {
            $source = "msstore"
            $program = $program.Substring("msstore:".Length)
        }

        Write-WinUtilLog -Component "Package" -Message "$Action winget package: $program (source: $source)"

        $outcome = "Failed"
        $detail = "no result"
        $exitCode = -1

        $arguments = switch ($Action) {
            "Uninstall" { @("uninstall", "--id", $program, "--source", $source, "--silent") }
            # --include-unknown because the scan that found these ran with it: without it winget
            # refuses every package whose installed version it could not read
            "Upgrade" {
                if ($upgradeAll) {
                    @("upgrade", "--all", "--accept-package-agreements", "--accept-source-agreements", "--include-unknown", "--silent")
                } else {
                    @("upgrade", "--id", $program, "--accept-package-agreements", "--accept-source-agreements", "--source", $source, "--include-unknown", "--silent")
                }
            }
            default     { @("install", "--id", $program, "--accept-package-agreements", "--accept-source-agreements", "--source", $source, "--silent") }
        }

        $process = Start-Process -FilePath winget -ArgumentList $arguments -NoNewWindow -Wait -PassThru
        $exitCode = $process.ExitCode

        # "Upgrade all" can fail because one configured source (commonly msstore) has a
        # temporary network error. Refresh source metadata once and retry the exact same
        # upgrade command. Never reset/remove sources and never loop indefinitely.
        $firstExitCodeHex = "{0:X8}" -f $exitCode
        if ($upgradeAll -and $transientNetworkExitCodes -contains $firstExitCodeHex) {
            Write-WinUtilLog -Level "WARN" -Component "Package" -Message "WinGet upgrade --all hit transient source error 0x$firstExitCodeHex. Updating sources and retrying once."

            $sourceUpdate = Start-Process -FilePath winget -ArgumentList @("source", "update") -NoNewWindow -Wait -PassThru
            Write-WinUtilLog -Component "Package" -Message "winget source update exited with code $($sourceUpdate.ExitCode)."

            if ($sourceUpdate.ExitCode -eq 0) {
                Start-Sleep -Seconds 2
            }

            $process = Start-Process -FilePath winget -ArgumentList $arguments -NoNewWindow -Wait -PassThru
            $exitCode = $process.ExitCode
        }

        if ($exitCode -eq 0) {
            $outcome = "Succeeded"
            $detail = "exit code 0"
        } elseif ($rebootExitCodes.ContainsKey($exitCode)) {
            $outcome = "Succeeded"
            $detail = $rebootExitCodes[$exitCode]
        } elseif ($nothingToDo.ContainsKey($exitCode)) {
            $outcome = "Skipped"
            $detail = $nothingToDo[$exitCode]
        } elseif ($exitCode -eq $adminContextProhibited) {
            $outcome = "Skipped"
            $detail = switch ($Action) {
                "Install" { "already installed for the current user; elevated WinUtil cannot update it" }
                "Upgrade" { "not upgraded; installed for the current user and elevated WinUtil cannot modify it" }
                "Uninstall" { "remains installed for the current user; elevated WinUtil cannot uninstall it" }
            }
        } else {
            $outcome = "Failed"
            $exitCodeHex = "{0:X8}" -f $exitCode
            if ($knownFailureDetails.ContainsKey($exitCodeHex)) {
                $detail = $knownFailureDetails[$exitCodeHex]
            } else {
                # The client module reports the same failure as a bare HRESULT, so the hex form and
                # Microsoft's own list serve both paths
                $detail = "WinGet reported 0x$exitCodeHex. See https://learn.microsoft.com/windows/package-manager/winget/returnCodes"
            }
        }

        $level = if ($outcome -eq "Failed") { "ERROR" } else { "INFO" }
        Write-WinUtilLog -Level $level -Component "Package" -Message "$Action winget package $($outcome.ToLowerInvariant()): $program ($detail)"

        [pscustomobject]@{
            Package = $program
            Manager = "winget"
            Action = $Action
            ExitCode = $exitCode
            Outcome = $outcome
            Detail = $detail
        }
    }
}
