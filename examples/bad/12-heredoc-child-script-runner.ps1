# PRF Example 12 — heredoc-child-script-runner
# Rules demonstrated: HD-001, HD-002, SEC-001
# Risk class: high
# NOTE: bad/*.ps1 are NEGATIVE training examples. Never execute them.

<#
Cleans stale build artifacts. The child step is composed as a string and
evaluated in the current session so the caller and the child share scope.
#>

$artifactRoot = 'C:\build\artifacts\stale'

$cleanup = @"
Remove-Item -LiteralPath C:\build\artifacts\stale\* -Force -Recurse
Write-Host 'stale artifacts removed'
"@

Invoke-Expression $cleanup
