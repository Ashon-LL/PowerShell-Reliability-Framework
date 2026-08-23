# PRF Example 02 — wildcard-delete-logs
# Rules demonstrated: SAFE-001, SAFE-002
# Risk class: high
# NOTE: bad/*.ps1 are NEGATIVE training examples. Never execute them.

<#
Frees disk space by clearing old logs out of every app folder.
Simple wildcard sweep, recursive, force so nothing prompts.
#>

$logRoot = 'C:\ProgramData\Contoso'

# Sweep every log under the root, no questions asked.
Get-ChildItem $logRoot -Filter *.log -Recurse |
    Remove-Item -Recurse -Force

# Same cleanup for IIS, just in case.
Get-ChildItem 'C:\inetpub\logs' -Filter *.log -Recurse |
    Remove-Item -Recurse -Force

Write-Host 'Disk space reclaimed.'
