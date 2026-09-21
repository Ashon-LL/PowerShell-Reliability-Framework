# PRF Example 12 — heredoc-child-script-runner
# Rules demonstrated: HD-001, HD-002, SEC-001
# Risk class: high
# NOTE: bad/*.ps1 are NEGATIVE training examples. Never execute them.

<#
Cleans stale build artifacts. The child step is generated as a real script file
and executed by path, so the deletion runs with its own explicit scope and its
own error handling instead of inheriting the caller's.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$ArtifactRoot = 'C:\build\artifacts\stale'
)

# SEC-001: generate a file and run it, never eval a composed string.
# The child body is a here-string, so the delimiter positions are visible and
# checkable instead of buried in an interpolated double-quoted string.
#
# HD-001: the closing delimiter starts at column one. Indenting it to match the
# surrounding block is a whole-file parse failure on both runtimes.
# HD-002: the header line carries nothing but whitespace after @'. A comment on
# the header line is not allowed and breaks the parse.
$child = @'
param(
    [Parameter(Mandatory = $true)][string]$Root
)

if (-not (Test-Path -LiteralPath $Root)) {
    Write-Warning "root not found: $Root"
    return
}

$targets = Get-ChildItem -LiteralPath $Root -File
$removed = 0
foreach ($file in $targets) {
    Remove-Item -LiteralPath $file.FullName -Force -Confirm:$false
    $removed += 1
}
Write-Host ("removed {0} file(s) from {1}" -f $removed, $Root)
'@

# The child is ASCII-only, so it parses correctly under both runtimes without a
# byte-order mark. Written through .NET so the bytes are what they look like.
$childPath = Join-Path ([System.IO.Path]::GetTempPath()) 'stale-artifact-cleanup.ps1'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($childPath, $child, $utf8NoBom)

if ($PSCmdlet.ShouldProcess($ArtifactRoot, "Clean stale artifacts via $childPath")) {
    & $childPath -Root $ArtifactRoot
}
