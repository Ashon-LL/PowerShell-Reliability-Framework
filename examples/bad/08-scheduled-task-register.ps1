# PRF Example 08 — scheduled-task-register
# Rules demonstrated: IDEM-009
# Risk class: medium
# NOTE: bad/*.ps1 are NEGATIVE training examples. Never execute them.

<#
Nightly cleanup: register a scheduled task for our maintenance
script. Rerunning just refreshes the definition.
#>

$action  = New-ScheduledTaskAction -Execute 'C:\Temp\cleanup.cmd'
$trigger = New-ScheduledTaskTrigger -Daily -At 2:30AM

Register-ScheduledTask -TaskName 'NightlyCleanup' -Action $action -Trigger $trigger

Write-Host 'Task registered for 2:30 AM daily.'
