# PRF Example 11 — heredoc-manifest-writer
# Rules demonstrated: HD-004, HD-009
# Risk class: medium
# NOTE: bad/*.ps1 are NEGATIVE training examples. Never execute them.

<#
Publishes the deployment receipt that a downstream checker hashes before
comparing it with the reference. The bytes have to be identical on every host,
because a hash comparison is the only thing standing between this receipt and
the reference it is checked against.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$ManifestPath = 'C:\temp\deploy-receipt.json'
)

$receipt = @'
{
  "service": "svc-01",
  "version": "1.4.2",
  "status": "published"
}
'@

# SAFE-005: an existing receipt is the previous run's evidence. Snapshot it
# before overwriting so a bad publish is still recoverable.
if (Test-Path -LiteralPath $ManifestPath) {
    $backup = "$ManifestPath.$((Get-Date).ToString('yyyyMMddHHmmss'))"
    Copy-Item -LiteralPath $ManifestPath -Destination $backup
}

# HD-004: Out-File defaults to UTF-16LE on Windows PowerShell 5.1 and to utf8NoBOM
# on PowerShell 7, so the same command produces two different files.
# HD-009: piping a here-string into a cmdlet sink also hands the cmdlet the final
# line, which it terminates with its own CRLF while the body carries bare LFs,
# leaving the artifact with mixed line endings.
#
# Serializing through .NET with a UTF8Encoding built without a byte-order mark
# removes both: measured byte-for-byte identical across the two runtimes.
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
if ($PSCmdlet.ShouldProcess($ManifestPath, 'Write deployment receipt')) {
    [System.IO.File]::WriteAllText($ManifestPath, $receipt, $utf8NoBom)
}

Write-Host "receipt written to $ManifestPath"
(Get-Item -LiteralPath $ManifestPath).Length
