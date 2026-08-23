# PRF Example 06 — azure-stop-vms-by-tag
# Rules demonstrated: SAFE-015
# Risk class: high
# NOTE: bad/*.ps1 are NEGATIVE training examples. Never execute them.

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$SubscriptionId = '00000000-0000-0000-0000-000000000000',
    [string]$ResourceGroup  = 'rg-dev-weu'
)

# SAFE-015: guard the blast radius FIRST. Confirm the active subscription
# before listing anything, and refuse to act outside the intended one.
$activeSub = az account show --query id -o tsv
if ($activeSub -ne $SubscriptionId) {
    throw "Active subscription is $activeSub, expected $SubscriptionId. Aborting."
}

# Double scope: one resource group AND the tag. No tenant-wide scans.
$rows = az vm list -g $ResourceGroup `
    --query "[?tags.env=='dev'].[name, resourceGroup]" -o tsv

if (-not $rows) {
    Write-Host "No dev-tagged VMs found in $ResourceGroup."
    return
}

foreach ($row in $rows) {
    $fields = $row -split "`t"
    $name = $fields[0]; $rg = $fields[1]
    # Preview first: invoke once with -WhatIf to review the target list.
    if ($PSCmdlet.ShouldProcess("$name ($rg)", 'Deallocate VM')) {
        az vm deallocate --name $name --resource-group $rg --no-wait
        Write-Host "Deallocation requested for $name."
    }
}
Write-Host 'Batch complete.'
