# PRF Example 03 — registry-service-startup-ensure
# Rules demonstrated: IDEM-005, SAFE-011
# Risk class: medium
# NOTE: bad/*.ps1 are NEGATIVE training examples. Never execute them.

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$ServiceName = 'ContosoSvc',
    [ValidateSet('Automatic', 'Manual', 'Disabled')]
    [string]$StartupType = 'Automatic'
)

$map = @{ Automatic = 2; Manual = 3; Disabled = 4 }
$key = "HKLM:\SYSTEM\CurrentControlSet\Services\$ServiceName"

# Existence guard: fail loudly when the service key is absent instead of
# letting Set-ItemProperty conjure a half-formed key out of thin air.
if (-not (Test-Path -LiteralPath $key)) {
    throw "Service '$ServiceName' has no registry key at $key."
}

# IDEM-005: read before write. When the value already matches, exit early --
# rerunning this script is a genuine no-op, not another registry churn.
$current = (Get-ItemProperty -LiteralPath $key -Name Start -ErrorAction SilentlyContinue).Start
if ($current -eq $map[$StartupType]) {
    Write-Host "'$ServiceName' already starts $StartupType (Start=$current). Nothing to do."
    return
}

# SAFE-011: -Force here is scoped: it overwrites exactly the named property
# we just read on a key we just verified. State that; don't blanket -Force.
if ($PSCmdlet.ShouldProcess("$key :: Start", "Change $current -> $($map[$StartupType]) ($StartupType)")) {
    Set-ItemProperty -LiteralPath $key -Name Start -Value $map[$StartupType] -Type DWord -Force
    $now = (Get-ItemProperty -LiteralPath $key -Name Start).Start
    Write-Host "'$ServiceName' Start value: $current -> $now."
}
