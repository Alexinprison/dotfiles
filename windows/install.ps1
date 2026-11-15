# Install for the current Windows user; no administrator privileges required.
[CmdletBinding()]
param(
    [string]$ArchivePath,
    [switch]$NoStart
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Pin the official portable release and verify it before executing anything.
$version = '2.0.31'
$archiveHash = 'ca1a595aca4528755d8d4cd7fed23d497a37bd9a0b6892072612d68dee1bd00a'
$url = "https://github.com/AutoHotkey/AutoHotkey/releases/download/v$version/AutoHotkey_$version.zip"
$installDir = Join-Path $env:LOCALAPPDATA 'dotfiles\keyboard'
$runtimeDir = Join-Path $installDir "AutoHotkey-$version"
$exe = Join-Path $runtimeDir 'AutoHotkey64.exe'
$source = Join-Path $PSScriptRoot 'capslock.ahk'
$destination = Join-Path $installDir 'capslock.ahk'
$startup = [Environment]::GetFolderPath('Startup')
$shortcutPath = Join-Path $startup 'Dotfiles CapsLock.lnk'

if (-not [Environment]::Is64BitOperatingSystem) {
    throw 'This installer requires 64-bit Windows.'
}
if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
    throw "Missing script: $source"
}

if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) {
    $tempDir = Join-Path ([IO.Path]::GetTempPath()) ('dotfiles-keyboard-' + [guid]::NewGuid())
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    try {
        if ($ArchivePath) {
            $zip = (Resolve-Path -LiteralPath $ArchivePath).Path
        } else {
            $zip = Join-Path $tempDir 'AutoHotkey.zip'
            Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $zip
        }
        if ((Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash -ne $archiveHash) {
            throw 'AutoHotkey archive SHA-256 mismatch.'
        }
        $extracted = Join-Path $tempDir 'extracted'
        Expand-Archive -LiteralPath $zip -DestinationPath $extracted
        if (-not (Test-Path -LiteralPath (Join-Path $extracted 'AutoHotkey64.exe'))) {
            throw 'AutoHotkey64.exe is missing from the verified archive.'
        }
        New-Item -ItemType Directory -Path $runtimeDir -Force | Out-Null
        Copy-Item -Path (Join-Path $extracted '*') -Destination $runtimeDir -Recurse -Force
    } finally {
        Remove-Item -LiteralPath $tempDir -Recurse -Force
    }
}

# Check syntax without executing the script or installing keyboard hooks.
$validation = Start-Process -FilePath $exe -ArgumentList @('/ErrorStdOut', '/Validate', ('"' + $source + '"')) -PassThru -Wait
if ($validation.ExitCode -ne 0) {
    throw "AutoHotkey validation failed with exit code $($validation.ExitCode)."
}

New-Item -ItemType Directory -Path $installDir -Force | Out-Null
if (Test-Path -LiteralPath $destination) {
    if ((Get-FileHash -LiteralPath $destination).Hash -ne (Get-FileHash -LiteralPath $source).Hash) {
        $backup = $destination + '.' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '.bak'
        Copy-Item -LiteralPath $destination -Destination $backup
    }
}
Copy-Item -LiteralPath $source -Destination $destination -Force

# Use Windows-local paths so login does not depend on WSL being started.
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $exe
$shortcut.Arguments = '"' + $destination + '"'
$shortcut.WorkingDirectory = $installDir
$shortcut.Description = 'CapsLock: tap for Escape, hold for Control'
$shortcut.Save()

if (-not $NoStart) {
    # #SingleInstance Force replaces only this script's previous instance.
    $process = Start-Process -FilePath $exe -ArgumentList @('/ErrorStdOut', ('"' + $destination + '"')) -PassThru
    Start-Sleep -Milliseconds 750
    if ($process.HasExited) {
        throw "CapsLock remapper exited unexpectedly ($($process.ExitCode))."
    }
    Write-Output "CapsLock remapper running (PID $($process.Id))."
}
Write-Output "Script: $destination"
Write-Output "Login shortcut: $shortcutPath"
