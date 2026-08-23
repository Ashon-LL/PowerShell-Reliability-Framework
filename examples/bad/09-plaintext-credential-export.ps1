# PRF Example 09 — plaintext-credential-export
# Rules demonstrated: SEC-014
# Risk class: critical
# NOTE: bad/*.ps1 are NEGATIVE training examples. Never execute them.

<#
Handy offline copy of the service-account credentials so the
on-call laptop can reconnect without the vault.
#>

$cred = Get-Credential -Message 'Service account for the migration'

$export = @{
    user     = $cred.UserName
    password = $cred.GetNetworkCredential().Password
    created  = Get-Date
}

# Stash next to the scripts so it rides along with repo backups.
$export | ConvertTo-Json | Set-Content -Path 'C:\Temp\migration-creds.json'

Write-Host 'Credentials exported. Keep the file handy!'
