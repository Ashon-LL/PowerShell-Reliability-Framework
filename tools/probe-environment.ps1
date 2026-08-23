#Requires -Version 5.1
<#
.SYNOPSIS
    PRF canonical environment probe (v0.1.0).

.DESCRIPTION
    Run BEFORE generating or executing any PowerShell against a machine.
    Emits one object describing OS, PowerShell runtime, elevation, domain join,
    execution policy, language mode, and availability of common enterprise
    modules. Per PRF Step 1, agents must treat probe failures or contradictions
    as a STOP signal, never as an assumption.

.EXAMPLE
    ./probe-environment.ps1
    ./probe-environment.ps1 -AsJson
#>
[CmdletBinding()]
param(
    # Emit a single JSON document instead of formatted text.
    [switch]$AsJson
)

$ErrorActionPreference = 'SilentlyContinue'

$identity   = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal  = New-Object Security.Principal.WindowsPrincipal($identity)
$isElevated = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

$os = Get-CimInstance -ClassName Win32_OperatingSystem
$cs = Get-CimInstance -ClassName Win32_ComputerSystem

$moduleNames = @(
    'ActiveDirectory', 'DnsServer', 'ScheduledTasks',
    'Az.Accounts', 'Microsoft.Graph.Authentication',
    'ExchangeOnlineManagement', 'Pester', 'PSScriptAnalyzer'
)

$modules = foreach ($name in $moduleNames) {
    $found = Get-Module -ListAvailable -Name $name |
        Sort-Object Version -Descending | Select-Object -First 1
    [pscustomobject]@{
        Name      = $name
        Available = [bool]$found
        Version   = if ($found) { $found.Version.ToString() } else { $null }
    }
}

$result = [pscustomobject]([ordered]@{
    ProbeTimeUtc            = (Get-Date).ToUniversalTime().ToString('o')
    OsCaption               = if ($os) { $os.Caption } else { 'unknown' }
    OsVersion               = [Environment]::OSVersion.Version.ToString()
    PsVersion               = $PSVersionTable.PSVersion.ToString()
    PsEdition               = $PSVersionTable.PSEdition
    Is64BitProcessOn64BitOs = '{0}/{1}' -f [Environment]::Is64BitProcess,
                                        [Environment]::Is64BitOperatingSystem
    IsElevated              = $isElevated
    PartOfDomain            = if ($cs) { $cs.PartOfDomain } else { $null }
    Domain                  = if ($cs) { $cs.Domain } else { $null }
    ExecutionPolicy         = (@(Get-ExecutionPolicy -List | ForEach-Object {
                                  '{0}={1}' -f $_.Scope, $_.ExecutionPolicy
                              }) -join '; ')
    LanguageMode            = $ExecutionContext.SessionState.LanguageMode
    Modules                 = @($modules)
})

if ($AsJson) {
    $result | ConvertTo-Json -Depth 4
} else {
    $result | Format-List
    $result.Modules | Format-Table -AutoSize
}
