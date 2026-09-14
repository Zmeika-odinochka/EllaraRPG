param(
    [Parameter(Mandatory = $true)][string]$GodotPath,
    [switch]$IncludeVisual
)

# No production saves are used. Each persistence test owns its temporary directory.
$projectDirectory = Split-Path -Parent $PSScriptRoot
$checks = @('guild_smoke', 'quest_flow', 'quest_completion', 'save_and_pause',
            'quests_inventory', 'keyboard_input', 'ui_workflow', 'display_options', 'exploration', 'combat', 'city', 'progression')
if ($IncludeVisual) { $checks += 'character_animation' }
$failedChecks = @()
foreach ($checkName in $checks) {
    $arguments = @('--path', $projectDirectory, '--script', "res://tests/$checkName.gd")
    if ($checkName -ne 'character_animation') { $arguments = @('--headless') + $arguments }
    $output = & $GodotPath @arguments 2>&1
    $exitCode = $LASTEXITCODE
    $errors = $output | Where-Object { "$_" -match 'SCRIPT ERROR|^ERROR:|FAIL:' }
    if ($exitCode -ne 0 -or $errors) {
        $failedChecks += $checkName
        Write-Output "FAIL $checkName (exit $exitCode)"
        $output | ForEach-Object { Write-Output "$_" }
    } else {
        Write-Output "PASS $checkName"
    }
}
if ($failedChecks.Count -gt 0) {
    Write-Output ("Failed checks: " + ($failedChecks -join ', '))
    exit 1
}
Write-Output "All $($checks.Count) checks passed without engine script errors."
