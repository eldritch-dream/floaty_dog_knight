# Doggo Knight — Run GUT Tests
# Usage: .\run_tests.ps1
# Prerequisites: Godot 4.5.1 console exe on PATH or at $GODOT_EXE

$GodotExe = if ($env:GODOT_EXE) { $env:GODOT_EXE } else { "C:\Users\smili\Documents\Godot\Installs\Godot_v4.5.1-stable_win64_console.exe" }
$ProjectPath = $PSScriptRoot

$env:GODOT_DISABLE_LEAK_CHECKS = "1"

$outFile = [System.IO.Path]::GetTempFileName()
$errFile = [System.IO.Path]::GetTempFileName()

Write-Host "Running GUT tests..." -ForegroundColor Cyan
$proc = Start-Process -FilePath $GodotExe `
    -ArgumentList "--headless","--path",$ProjectPath,"--display-driver","headless","--audio-driver","Dummy","-s","addons/gut/gut_cmdln.gd","-gdir=res://tests","-ginclude_subdirs","-gexit" `
    -Wait -PassThru -NoNewWindow `
    -RedirectStandardOutput $outFile `
    -RedirectStandardError $errFile

$stdout = Get-Content $outFile -Raw
$stderr = Get-Content $errFile -Raw
Remove-Item $outFile, $errFile -ErrorAction SilentlyContinue

# Strip ANSI escape codes for clean output
$clean = $stdout -replace '\x1b\[[0-9;]*m', ''
Write-Host $clean

if ($stderr) {
    Write-Host "STDERR:" -ForegroundColor Yellow
    Write-Host $stderr
}

if ($proc.ExitCode -ne 0) {
    Write-Host "TESTS FAILED (exit code $($proc.ExitCode))" -ForegroundColor Red
} else {
    Write-Host "ALL TESTS PASSED" -ForegroundColor Green
}

# Kill any lingering Godot processes (GUT -gexit sometimes doesn't terminate cleanly)
Start-Sleep 2
Get-Process | Where-Object { $_.Name -like "*Godot*" -and $_.Id -ne $PID } | Stop-Process -Force -ErrorAction SilentlyContinue

exit $proc.ExitCode
