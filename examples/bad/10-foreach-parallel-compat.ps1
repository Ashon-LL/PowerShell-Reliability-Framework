# PRF Example 10 — foreach-parallel-compat
# Rules demonstrated: COMP-001
# Risk class: low
# NOTE: bad/*.ps1 are NEGATIVE training examples. Never execute them.

<#
Probe the whole farm quickly with parallel foreach. Modern
PowerShell does this everywhere now.
#>

$servers = Get-Content 'C:\configs\farm.txt'

$results = $servers | ForEach-Object -Parallel {
    Test-Connection -ComputerName $_ -Count 1 -Quiet
}

Write-Host "Reachable: $(@($results | Where-Object { $_ }).Count) of $($servers.Count)"
