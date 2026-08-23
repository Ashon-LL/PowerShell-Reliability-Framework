# PRF Example 04 — service-retry-restart
# Rules demonstrated: ERR-013, ERR-001
# Risk class: medium
# NOTE: bad/*.ps1 are NEGATIVE training examples. Never execute them.

<#
Restart ContosoSvc after config changes. Dependents bounce back
on their own, so keep it simple.
#>

$svc = 'ContosoSvc'

Restart-Service -Name $svc -Force

# Give it a moment, then check once.
Start-Sleep -Seconds 5
$status = (Get-Service -Name $svc).Status
Write-Host "$svc is now $status."

# If something throws, the console will show it anyway.
