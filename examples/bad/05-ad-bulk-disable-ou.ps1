# PRF Example 05 — ad-bulk-disable-ou
# Rules demonstrated: SAFE-013, ERR-001
# Risk class: high
# NOTE: bad/*.ps1 are NEGATIVE training examples. Never execute them.

<#
Disable stale AD accounts. Everyone whose password expired gets
switched off in one clean pipeline.
#>

Import-Module ActiveDirectory

# Pull ALL matching users domain-wide, then disable the lot.
Get-ADUser -Filter { Enabled -eq $true -and PasswordExpired -eq $true } |
    Disable-ADAccount -Confirm:$false

Write-Host 'Stale accounts disabled.'
