[CmdletBinding()]
param(
    [ValidateSet('build', 'patch', 'minor', 'major')]
    [string]$Bump = 'build',

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Summary,

    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$pubspecPath = Join-Path $repoRoot 'flutter\pubspec.yaml'
$historyPath = Join-Path $repoRoot 'docs\BUILD_HISTORY.md'
$pubspec = Get-Content -LiteralPath $pubspecPath -Raw
$versionPattern = '(?m)^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$'
$match = [regex]::Match($pubspec, $versionPattern)

if (-not $match.Success) {
    throw 'Versi pada flutter/pubspec.yaml tidak ditemukan atau formatnya tidak valid.'
}

$major = [int]$match.Groups[1].Value
$minor = [int]$match.Groups[2].Value
$patch = [int]$match.Groups[3].Value
$build = [int]$match.Groups[4].Value + 1

switch ($Bump) {
    'patch' {
        $patch++
    }
    'minor' {
        $minor++
        $patch = 0
    }
    'major' {
        $major++
        $minor = 0
        $patch = 0
    }
}

$version = "$major.$minor.$patch"
$fullVersion = "$version+$build"
$safeSummary = $Summary.Replace('|', '/').Trim()
$today = Get-Date -Format 'yyyy-MM-dd'
$historyRow = "| $version | $build | $today | $Bump | $safeSummary | Draft | ``pending`` |"

Write-Host "Versi saat ini : $($match.Value.Replace('version:', '').Trim())"
Write-Host "Versi berikut  : $fullVersion"
Write-Host "Ringkasan      : $safeSummary"

if (-not $Apply) {
    Write-Host ''
    Write-Host 'Preview saja. Tambahkan -Apply untuk mengubah pubspec dan BUILD_HISTORY.'
    exit 0
}

$versionRegex = [regex]::new($versionPattern)
$updatedPubspec = $versionRegex.Replace($pubspec, "version: $fullVersion", 1)
[System.IO.File]::WriteAllText($pubspecPath, $updatedPubspec)

$history = Get-Content -LiteralPath $historyPath -Raw
$marker = '<!-- NEXT_BUILD_ROW -->'
if (-not $history.Contains($marker)) {
    throw 'Marker NEXT_BUILD_ROW tidak ditemukan di docs/BUILD_HISTORY.md.'
}
$updatedHistory = $history.Replace($marker, "$marker`r`n$historyRow")
[System.IO.File]::WriteAllText($historyPath, $updatedHistory)

Write-Host ''
Write-Host 'Nomor build dan riwayat sudah diperbarui.'
Write-Host 'Selanjutnya: lengkapi CHANGELOG, jalankan tes, buat PR, lalu buat Git tag.'
