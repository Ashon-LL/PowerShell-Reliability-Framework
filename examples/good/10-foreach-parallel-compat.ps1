# PRF Example 10 — foreach-parallel-compat
# Rules demonstrated: COMP-001
# Risk class: low
# NOTE: bad/*.ps1 are NEGATIVE training examples. Never execute them.

[CmdletBinding()]
param([string]$ServerList = 'C:\configs\farm.txt')

$servers = @(Get-Content -LiteralPath $ServerList)

# COMP-001: verify the engine version BEFORE calling edition-specific
# features. ForEach-Object -Parallel requires PowerShell 7+; on Windows
# PowerShell 5.1 it throws a parameter-not-found error.
$supportsParallel = $PSVersionTable.PSVersion.Major -ge 7

if ($supportsParallel) {
    $results = $servers | ForEach-Object -ThrottleLimit 16 -Parallel {
        [pscustomobject]@{ Server = $_; Up = (Test-Connection -ComputerName $_ -Count 1 -Quiet) }
    }
} else {
    Write-Warning 'PowerShell 7 not detected; falling back to sequential probes.'
    $results = foreach ($server in $servers) {
        [pscustomobject]@{ Server = $server; Up = (Test-Connection -ComputerName $server -Count 1 -Quiet) }
    }
}

$up = @($results | Where-Object Up).Count
Write-Host "Reachable: $up of $($servers.Count) hosts."

# COMP-001 companion habit: assert loudly when the fast path is mandatory.
if (-not $supportsParallel -and $env:REQUIRE_PARALLEL -eq '1') {
    throw 'This workload requires PowerShell 7+ for parallel probing.'
}
