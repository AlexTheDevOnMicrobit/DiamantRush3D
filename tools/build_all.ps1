# Exporte le jeu pour Windows, Linux, Web, macOS (et Android si configuré, voir docs/ANDROID.md).
# Usage : .\tools\build_all.ps1 -Godot "C:\chemin\Godot_v4.3-stable_win64_console.exe" [-Targets windows,linux,web,macos,android,aab]
param(
    [string]$Godot = "godot",
    [string[]]$Targets = @("windows", "linux", "web", "macos")
)
$ErrorActionPreference = "Continue"
Set-Location (Join-Path $PSScriptRoot "..")
$version = ([regex]::Match((Get-Content project.godot -Raw), 'config/version="([^"]+)"')).Groups[1].Value
& $Godot --headless --path . --import 2>&1 | Out-Null
New-Item -ItemType Directory -Force build, dist | Out-Null
$map = @{
    windows = @("Windows Desktop", "build/windows/DiamantRush3D.exe")
    linux   = @("Linux", "build/linux/DiamantRush3D.x86_64")
    web     = @("Web", "build/web/index.html")
    macos   = @("macOS", "build/macos/DiamantRush3D.zip")
    android = @("Android", "build/android/DiamantRush3D.apk")
    aab     = @("Android AAB (Google Play)", "build/android/DiamantRush3D.aab")
}
$fail = 0
foreach ($t in $Targets) {
    if (-not $map.ContainsKey($t)) { Write-Host "Cible inconnue : $t"; $fail = 1; continue }
    $preset, $out = $map[$t]
    New-Item -ItemType Directory -Force (Split-Path $out) | Out-Null
    Write-Host "==> $preset"
    & $Godot --headless --path . --export-release $preset $out 2>&1 | Select-Object -Last 3
    if ((Test-Path $out) -and (Get-Item $out).Length -gt 0) { Write-Host "    OK : $out" } else { Write-Host "    ECHEC : $preset"; $fail = 1 }
}
if (Test-Path build/windows/DiamantRush3D.exe) { Compress-Archive -Force build/windows/DiamantRush3D.exe "dist/DiamantRush3D-$version-windows.zip" }
if (Test-Path build/linux/DiamantRush3D.x86_64) { Compress-Archive -Force build/linux/DiamantRush3D.x86_64 "dist/DiamantRush3D-$version-linux.zip" }
if (Test-Path build/web/index.html) { Compress-Archive -Force build/web/* "dist/DiamantRush3D-$version-web.zip" }
if (Test-Path build/macos/DiamantRush3D.zip) { Copy-Item -Force build/macos/DiamantRush3D.zip "dist/DiamantRush3D-$version-macos.zip" }
if (Test-Path build/android/DiamantRush3D.apk) { Copy-Item -Force build/android/DiamantRush3D.apk "dist/DiamantRush3D-$version-android.apk" }
if (Test-Path build/android/DiamantRush3D.aab) { Copy-Item -Force build/android/DiamantRush3D.aab "dist/DiamantRush3D-$version-android.aab" }
Write-Host "Archives dans dist/ :"
Get-ChildItem dist | Select-Object Name
exit $fail
