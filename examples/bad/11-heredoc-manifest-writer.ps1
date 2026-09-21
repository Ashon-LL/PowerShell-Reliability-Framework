# PRF Example 11 — heredoc-manifest-writer
# Rules demonstrated: HD-004, HD-009
# Risk class: medium
# NOTE: bad/*.ps1 are NEGATIVE training examples. Never execute them.

<#
Publishes the deployment receipt that a downstream checker hashes before
comparing it with the reference. Kept short by using the cmdlet defaults.
#>

$manifestPath = 'C:\temp\deploy-receipt.json'

$receipt = @'
{
  "service": "svc-01",
  "version": "1.4.2",
  "status": "published"
}
'@ | Out-File $manifestPath

Write-Host "receipt written to $manifestPath"
(Get-Item -LiteralPath $manifestPath).Length
