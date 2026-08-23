# PRF Example 07 — firewall-rule-ensure
# Rules demonstrated: IDEM-008
# Risk class: medium
# NOTE: bad/*.ps1 are NEGATIVE training examples. Never execute them.

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$RuleName   = 'ContosoApp-8443-In-TCP',
    [int]   $Port       = 8443,
    [string[]]$Profiles = @('Domain', 'Private')
)

# IDEM-008: look up by stable RULE NAME (not DisplayName) before creating.
# An unconditional New-NetFirewallRule stacks duplicate rules every rerun.
$existing = Get-NetFirewallRule -Name $RuleName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "Rule '$RuleName' already exists (Enabled=$($existing.Enabled)). Nothing to do."
    return
}

if (-not $PSCmdlet.ShouldProcess($RuleName, "Create inbound TCP/$Port allow rule")) {
    return   # -WhatIf prints its preview line and exits here.
}

New-NetFirewallRule -Name $RuleName -DisplayName $RuleName `
    -Direction Inbound -Protocol TCP -LocalPort $Port `
    -Action Allow -Profile $Profiles -Enabled True | Out-Null

# Post-write verification: confirm the rule actually landed.
if (-not (Get-NetFirewallRule -Name $RuleName -ErrorAction SilentlyContinue)) {
    throw "Rule '$RuleName' still missing after creation."
}
Write-Host "Ensured '$RuleName': TCP/$Port Allow, profiles $($Profiles -join ',')."
