# PRF Example 01 — download-execute-cradle
# Rules demonstrated: SEC-002, SEC-003
# Risk class: critical
# NOTE: bad/*.ps1 are NEGATIVE training examples. Never execute them.

<#
Installs the Contoso monitoring agent by fetching the official
bootstrap script and running it straight from the web.
One step, no temp files, no fuss.
#>

param(
    [string]$BaseUrl = 'https://tools.contoso.example/bootstrap'
)

$url = "$BaseUrl/install-agent.ps1"

Write-Host "Fetching installer from $url ..."
$response = Invoke-WebRequest -Uri $url -UseBasicParsing

# Run the downloaded script content directly.
Invoke-Expression $response.Content

Write-Host 'Agent install complete.'
