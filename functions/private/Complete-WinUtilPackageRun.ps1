function Complete-WinUtilPackageRun {
    <#
        .SYNOPSIS
            Reports what a package run actually did and fails the job on unexpected errors

        .DESCRIPTION
            Package managers report failure through an exit code, which is easy to walk past.
            Without this the job layer would show a green checkmark for a run in which nothing
            changed. Unexpected failures terminate the job; expected elevated-context skips
            raise a warning so the job cannot claim that every requested action completed.

        .PARAMETER Action
            Install or Uninstall, used in the summary text.

    #>
    param(
        [Parameter(Mandatory)]
        [string]$Action,

        [object[]]$Results = @()
    )

    $succeeded = @($Results | Where-Object { $_.Outcome -eq "Succeeded" })
    $skipped = @($Results | Where-Object { $_.Outcome -eq "Skipped" })
    $failed = @($Results | Where-Object { $_.Outcome -eq "Failed" })

    $summary = "$($succeeded.Count) succeeded, $($skipped.Count) skipped, $($failed.Count) failed"
    Write-WinUtilLog -Component "Package" -Message "$Action summary: $summary"

    if ($sync.preferences.language -eq 'ru-RU') {
        $actionLabel = switch ($Action) {
            'Install' { 'Установка' }
            'Uninstall' { 'Удаление' }
            'Upgrade' { 'Обновление' }
            default { $Action }
        }
        Write-Host "$actionLabel: успешно — $($succeeded.Count), пропущено — $($skipped.Count), ошибок — $($failed.Count)"
    } else {
        Write-Host "$Action summary: $summary"
    }

    foreach ($result in $skipped) {
        $detail = Convert-WinUtilRussianRuntimeText (Convert-WinUtilRussianText $result.Detail)
        if ($sync.preferences.language -eq 'ru-RU') {
            Write-Host "  пропущено  $($result.Package) - $detail"
        } else {
            Write-Host "  skipped  $($result.Package) - $detail"
        }
    }
    foreach ($result in $failed) {
        $detail = Convert-WinUtilRussianRuntimeText (Convert-WinUtilRussianText $result.Detail)
        if ($sync.preferences.language -eq 'ru-RU') {
            Write-Host "  ошибка  $($result.Package) - $detail" -ForegroundColor Red
        } else {
            Write-Host "  failed   $($result.Package) - $detail" -ForegroundColor Red
        }
    }

    $adminContextSkipped = @($skipped | Where-Object { $_.ExitCode -eq -1978335107 })
    if ($adminContextSkipped.Count -gt 0) {
        Write-Warning "$($adminContextSkipped.Count) package action(s) were skipped because elevated WinUtil cannot modify user-scoped installations."
    }

    if ($failed.Count -gt 0) {
        $names = ($failed | ForEach-Object { $_.Package }) -join ', '
        $reasons = @($failed | ForEach-Object { $_.Detail } | Sort-Object -Unique)

        $message = if ($reasons.Count -eq 1) {
            "$($failed.Count) of $($Results.Count) package(s) failed: $names. $($reasons[0])"
        } else {
            "$($failed.Count) of $($Results.Count) package(s) failed: $names. See the lines above for each reason."
        }
        # Each failed package was already logged by its package-manager adapter. Carry that fact
        # with the summary exception so the job wrapper adds context without another error count.
        $exception = [System.InvalidOperationException]::new($message)
        $exception.Data["WinUtilErrorReported"] = $true
        throw $exception
    }
}
