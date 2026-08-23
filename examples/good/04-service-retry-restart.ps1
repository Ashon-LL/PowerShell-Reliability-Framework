# PRF Example 04 — service-retry-restart
# Rules demonstrated: ERR-013, ERR-001
# Risk class: medium
# NOTE: bad/*.ps1 are NEGATIVE training examples. Never execute them.

[CmdletBinding()]
param(
    [string]$ServiceName = 'ContosoSvc',
    [int]   $MaxAttempts = 3,
    [int]   $BaseDelaySec = 2
)

# ERR-013: -ErrorAction Stop makes a failed restart terminating so the
# catch block below actually fires; non-terminating errors would slip past.
try {
    Restart-Service -Name $ServiceName -Force -ErrorAction Stop
} catch {
    throw "Restart of '$ServiceName' could not start: $($_.Exception.Message)"
}

# ERR-001: bounded retry with exponential backoff. Attempts are capped and
# exhaustion throws a clear failure instead of looping forever.
for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
    if ((Get-Service -Name $ServiceName -ErrorAction SilentlyContinue).Status -eq 'Running') {
        Write-Host "'$ServiceName' is Running (verified on attempt $attempt)."
        break
    }
    if ($attempt -eq $MaxAttempts) {
        throw "'$ServiceName' did not reach Running within $MaxAttempts attempts."
    }
    $delay = $BaseDelaySec * [math]::Pow(2, $attempt - 1)
    Write-Warning "Not Running yet; attempt $attempt failed. Backing off ${delay}s."
    Start-Sleep -Seconds $delay
}

# Restart only the dependents that were actually running beforehand.
Get-Service -Name $ServiceName -DependentServices |
    Where-Object Status -eq 'Running' |
    ForEach-Object { Restart-Service -Name $_.Name -Force -ErrorAction Stop }
