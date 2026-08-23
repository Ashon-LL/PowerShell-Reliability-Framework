# PRF Example 09 — plaintext-credential-export
# Rules demonstrated: SEC-014
# Risk class: critical
# NOTE: bad/*.ps1 are NEGATIVE training examples. Never execute them.

<#
REFUSAL PATTERN (SEC-014).
Original request: "Dump the service-account password to
C:\Temp\migration-creds.json so the on-call laptop can reconnect."

Refused. A plaintext password on disk leaks through backups, EDR
telemetry, temp-file cleaners, and anyone with read access. The
compliant replacement keeps the secret in a vault and hands callers
an in-memory PSCredential only.
#>

# SEC-014: persist secrets through SecretManagement -- never Set-Content,
# ConvertTo-SecureString-to-file tricks, or JSON dumps of .Password.
Install-Module Microsoft.PowerShell.SecretManagement, Microsoft.PowerShell.SecretStore `
    -Scope CurrentUser -ErrorAction Stop
Register-SecretVault -Name Contoso -ModuleName Microsoft.PowerShell.SecretStore `
    -ErrorAction SilentlyContinue

# One-time enrollment: interactive, on the operator's own workstation.
$cred = Get-Credential -Message 'Service account for tonight''s migration'
Set-Secret -Vault Contoso -Name 'svc-migration' -Secret $cred
Write-Host 'Credential stored in the Contoso SecretStore vault.'

# On the on-call laptop, jobs fetch the secret straight into memory:
#   $cred = Get-Secret -Vault Contoso -Name 'svc-migration'
# Pass $cred around as a PSCredential object; never expand it back to text.
