# PRF Example 03 — registry-service-startup-ensure
# Rules demonstrated: IDEM-005, SAFE-011
# Risk class: medium
# NOTE: bad/*.ps1 are NEGATIVE training examples. Never execute them.

<#
Make sure ContosoSvc always starts automatically by writing its
Start value straight into the registry. Fast and reliable.
#>

$key = 'HKLM:\SYSTEM\CurrentControlSet\Services\ContosoSvc'

# Force the value every run; what was there before doesn't matter.
Set-ItemProperty -Path $key -Name Start -Value 2 -Type DWord -Force

# Bonus: reset the delayed-autostart flag while we're in here.
Set-ItemProperty -Path $key -Name DelayedAutostart -Value 0 -Type DWord -Force

Write-Host 'ContosoSvc startup type forced to Automatic.'
