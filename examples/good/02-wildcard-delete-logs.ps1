# PRF Example 02 — wildcard-delete-logs
# Rules demonstrated: SAFE-001, SAFE-002
# Risk class: high
# NOTE: bad/*.ps1 are NEGATIVE training examples. Never execute them.

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$LogRoot       = 'C:\ProgramData\Contoso\Logs',
    [int]   $OlderThanDays = 30,
    [string]$NamePattern   = 'app-*.log'
)

$cutoff = (Get-Date).AddDays(-$OlderThanDays)

# Enumerate first, delete later: build the exact target list up front so
# the -WhatIf preview shows every path a real run would remove.
$targets = Get-ChildItem -LiteralPath $LogRoot -Filter $NamePattern -File |
    Where-Object { $_.LastWriteTime -lt $cutoff }

if (-not $targets) {
    Write-Host "No '$NamePattern' files older than $OlderThanDays days under $LogRoot."
    return
}

# SAFE-002: preview before destruction. Run once with -WhatIf, read the
# printed list, and only then repeat the invocation without -WhatIf.
foreach ($file in $targets) {
    # SAFE-001: -LiteralPath pins deletion to this ONE resolved file object.
    # No wildcards, no recursion, nothing outside $targets is reachable.
    if ($PSCmdlet.ShouldProcess($file.FullName, "Delete log (older than $OlderThanDays days)")) {
        Remove-Item -LiteralPath $file.FullName -Force -Confirm:$false
    }
}

Write-Host ("Removed {0} log file(s) from {1}." -f @($targets).Count, $LogRoot)
