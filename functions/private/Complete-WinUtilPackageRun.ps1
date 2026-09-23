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

    $isRussian = $false
    $syncVariable = Get-Variable -Name sync -ErrorAction SilentlyContinue
    if ($null -ne $syncVariable -and $null -ne $syncVariable.Value.preferences) {
        $isRussian = $syncVariable.Value.preferences.language -eq 'ru-RU'
    }

    $convertDisplayText = {
        param([AllowNull()][object]$Text)

        $value = $Text
        if (Get-Command Convert-WinUtilRussianText -ErrorAction SilentlyContinue) {
            $value = Convert-WinUtilRussianText $value
        }
        if (Get-Command Convert-WinUtilRussianRuntimeText -ErrorAction SilentlyContinue) {
            $value = Convert-WinUtilRussianRuntimeText $value
        }
        return $value
    }

    $summary = "$($succeeded.Count) succeeded, $($skipped.Count) skipped, $($failed.Count) failed"
    Write-WinUtilLog -Component "Package" -Message "$Action summary: $summary"

    if ($isRussian) {
        $actionLabel = switch ($Action) {
            'Install' { 'Установка' }
            'Uninstall' { 'Удаление' }
            'Upgrade' { 'Обновление' }
            default { $Action }
        }
        Write-Host "${actionLabel}: успешно — $($succeeded.Count), пропущено — $($skipped.Count), ошибок — $($failed.Count)"
    } else {
        Write-Host "$Action summary: $summary"
    }

    foreach ($result in $skipped) {
        $detail = & $convertDisplayText $result.Detail
        if ($isRussian) {
            Write-Host "  пропущено  $($result.Package) - $detail"
        } else {
            Write-Host "  skipped  $($result.Package) - $detail"
        }
    }
    foreach ($result in $failed) {
        $detail = & $convertDisplayText $result.Detail
        if ($isRussian) {
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
