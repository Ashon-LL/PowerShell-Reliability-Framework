# PRF Example 06 — azure-stop-vms-by-tag
# Rules demonstrated: SAFE-015
# Risk class: high
# NOTE: bad/*.ps1 are NEGATIVE training examples. Never execute them.

<#
Overnight cost saver: stop every VM tagged env=dev, wherever
the account can see one.
#>

az login

# Find all dev VMs across everything visible, then stop them.
$vms = az vm list --query "[?tags.env=='dev'].{name:name, rg:resourceGroup}" -o json | ConvertFrom-Json

foreach ($vm in $vms) {
    Write-Host "Stopping $($vm.name) in $($vm.rg) ..."
    az vm deallocate --name $vm.name --resource-group $vm.rg --no-wait --yes
}

Write-Host 'All dev VMs stopped. See you tomorrow.'
