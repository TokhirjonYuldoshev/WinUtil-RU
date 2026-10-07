function Test-WinUtilBuildInputs {
    <# Ensures compiler, package and upstream-baseline inputs match HEAD. #>
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [string]$ExpectedCommit
    )

    function Invoke-WinUtilBuildGit {
        param([string[]]$Arguments)
        $previousPreference = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            $output = @(& git -C $RepositoryRoot @Arguments 2>&1)
            $code = $LASTEXITCODE
        } finally { $ErrorActionPreference = $previousPreference }
        if ($code -ne 0) { throw "Build input Git verification failed: $($output -join [Environment]::NewLine)" }
        return $output
    }

    $commit = ([string](@(Invoke-WinUtilBuildGit @('rev-parse', 'HEAD'))[0])).Trim()
    if ($ExpectedCommit -and $commit -ne $ExpectedCommit) { throw 'Source commit changed during the release build.' }
    $roots = @('functions', 'scripts', 'config', 'xaml')
    $files = @('Compile.ps1', 'tools/autounattend.xml', 'tools/WinUtilUpstreamBaseline.json', 'LICENSE')
    $tree = @(Invoke-WinUtilBuildGit (@('ls-tree', '-r', $commit, '--') + $roots + $files))
    $expected = @{}
    foreach ($entry in $tree) {
        if ([string]$entry -notmatch '^100(?:644|755) blob (?<Hash>[0-9a-f]{40})\t(?<Path>.+)$') {
            throw "Unsupported build input tree entry: $entry"
        }
        $expected[$Matches.Path] = $Matches.Hash
    }

    # Enumerate the filesystem, including ignored/untracked files. Compile.ps1
    # appends all files under functions, not only tracked PowerShell sources.
    $actual = @{}
    foreach ($root in $roots) {
        $directory = Join-Path $RepositoryRoot $root
        if (Test-Path -LiteralPath $directory) {
            foreach ($item in @(Get-ChildItem -LiteralPath $directory -Recurse -Force -File)) {
                $path = $item.FullName.Substring($RepositoryRoot.TrimEnd([IO.Path]::DirectorySeparatorChar).Length + 1).Replace('\', '/')
                $actual[$path] = $item
            }
        }
    }
    foreach ($path in $files) {
        if (Test-Path -LiteralPath (Join-Path $RepositoryRoot $path) -PathType Leaf) {
            $actual[$path] = Get-Item -LiteralPath (Join-Path $RepositoryRoot $path) -Force
        }
    }
    $mismatches = @()
    foreach ($path in $actual.Keys) {
        if (-not $expected.ContainsKey($path)) { $mismatches += $path; continue }
        if (($actual[$path].Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            $mismatches += $path; continue
        }
        # Apply Git's configured line-ending filters, as for a normal checkout,
        # but read actual bytes even when the index says assume-unchanged.
        $hash = ([string](@(Invoke-WinUtilBuildGit @('hash-object', "--path=$path", '--', $path))[0])).Trim()
        if ($hash -ne $expected[$path]) { $mismatches += $path }
    }
    foreach ($path in $expected.Keys) {
        if (-not $actual.ContainsKey($path)) { $mismatches += $path }
    }
    if ($mismatches.Count) {
        throw "Build inputs must match committed HEAD. Changed, missing or extra inputs: $((@($mismatches | Sort-Object -Unique)) -join ', ')"
    }
    return $commit
}
