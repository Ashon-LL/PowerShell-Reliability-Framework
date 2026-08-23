# PRF Example 07 — firewall-rule-ensure
# Rules demonstrated: IDEM-008
# Risk class: medium
# NOTE: bad/*.ps1 are NEGATIVE training examples. Never execute them.

<#
Open the app's ports during setup. Just create the rules;
duplicate rules are harmless anyway.
#>

New-NetFirewallRule -DisplayName 'Contoso App Port' `
    -Direction Inbound -Protocol TCP -LocalPort 8443 `
    -Action Allow -Profile Any

New-NetFirewallRule -DisplayName 'Contoso Health Probe' `
    -Direction Inbound -Protocol TCP -LocalPort 9443 `
    -Action Allow -Profile Any

Write-Host 'Firewall rules created.'
