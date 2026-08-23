# PRF Example 05 — ad-bulk-disable-ou
# Rules demonstrated: SAFE-013, ERR-001
# Risk class: high
# NOTE: bad/*.ps1 are NEGATIVE training examples. Never execute them.

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$SearchBase   = 'OU=Contractors,DC=contoso,DC=local',
    [int]   $InactiveDays = 90
)

Import-Module ActiveDirectory
$cutoff = (Get-Date).AddDays(-$InactiveDays)

# SAFE-013: bulk identity changes are scoped to ONE OU via -SearchBase,
# never a domain-wide filter; -Filter then narrows to genuinely inactive
# accounts only.
$users = Get-ADUser -SearchBase $SearchBase -SearchScope Subtree `
    -Filter { Enabled -eq $true -and LastLogonDate -lt $cutoff } `
    -Properties LastLogonDate

# Run me with -WhatIf first: ShouldProcess prints every would-be disable.
$disabled = 0; $failed = @()
foreach ($user in $users) {
    if ($PSCmdlet.ShouldProcess($user.SamAccountName, 'Disable AD account')) {
        # ERR-001: tally per-object outcomes; one bad object neither aborts
        # the batch nor disappears silently.
        try {
            Disable-ADAccount -Identity $user.DistinguishedName -Confirm:$false -ErrorAction Stop
            $disabled++
            Write-Host "Disabled $($user.SamAccountName)"
        } catch {
            $failed += $user.SamAccountName
            Write-Warning "Could not disable $($user.SamAccountName): $($_.Exception.Message)"
        }
    }
}

Write-Host "Summary: $disabled disabled, $($failed.Count) failed."
