[CmdletBinding()]
param(
    [switch]$SkipTests
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$flutterRoot = Join-Path $repoRoot 'flutter'
$localPropertiesPath = Join-Path $flutterRoot 'android\local.properties'
$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue

if ($flutterCommand) {
    $flutterExe = $flutterCommand.Source
} elseif (Test-Path -LiteralPath $localPropertiesPath) {
    $flutterSdkLine = Get-Content -LiteralPath $localPropertiesPath |
        Where-Object { $_ -match '^flutter\.sdk=' } |
        Select-Object -First 1
    if (-not $flutterSdkLine) {
        throw 'flutter.sdk tidak ditemukan di android/local.properties.'
    }
    $flutterSdk = ($flutterSdkLine -replace '^flutter\.sdk=', '') -replace '\\\\', '\'
    $flutterExe = Join-Path $flutterSdk 'bin\flutter.bat'
} else {
    throw 'Flutter SDK tidak ditemukan.'
}

$pubspec = Get-Content -LiteralPath (Join-Path $flutterRoot 'pubspec.yaml') -Raw
$versionMatch = [regex]::Match($pubspec, '(?m)^version:\s*([^\s]+)\s*$')
if (-not $versionMatch.Success) {
    throw 'Versi aplikasi tidak ditemukan.'
}

$fullVersion = $versionMatch.Groups[1].Value
$safeVersion = $fullVersion -replace '[^A-Za-z0-9._-]', '_'
$symbolsDirectory = Join-Path $flutterRoot "build\symbols\android-$safeVersion"

function Invoke-Flutter {
    param([Parameter(Mandatory = $true)][string[]]$FlutterArguments)

    & $flutterExe @FlutterArguments
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter gagal: $($FlutterArguments -join ' ')"
    }
}

Push-Location $flutterRoot
try {
    Invoke-Flutter @('pub', 'get')
    if (-not $SkipTests) {
        Invoke-Flutter @('analyze')
        Invoke-Flutter @('test')
    }
    Invoke-Flutter @(
        'build',
        'appbundle',
        '--release',
        "--split-debug-info=$symbolsDirectory"
    )
} finally {
    Pop-Location
}

$bundlePath = Join-Path $flutterRoot 'build\app\outputs\bundle\release\app-release.aab'
$bundle = Get-Item -LiteralPath $bundlePath
Write-Host ''
Write-Host "AAB       : $($bundle.FullName)"
Write-Host "Ukuran    : $([math]::Round($bundle.Length / 1MB, 2)) MB"
Write-Host "Symbols   : $symbolsDirectory"
Write-Host 'Simpan folder symbols bersama build ini untuk membaca crash report.'
