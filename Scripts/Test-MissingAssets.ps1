Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$clientRoot = Join-Path $root 'Client'
$assetsJsonPath = Join-Path $clientRoot 'assets.json'
$catalogPath = Join-Path $clientRoot 'assets\catalog-content.json'
$auditPath = Join-Path $root 'Docs\MISSING_ASSETS_AUDIT.md'

$failures = New-Object System.Collections.ArrayList
function Add-Failure {
    param([string]$Message)
    [void]$failures.Add($Message)
}

if (-not (Test-Path $assetsJsonPath)) {
    Add-Failure "Client/assets.json missing"
} else {
    $assets = Get-Content -Path $assetsJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($entry in @($assets.files)) {
        $localFile = [string]$entry.localfile
        if ([string]::IsNullOrWhiteSpace($localFile)) {
            Add-Failure "Asset entry without localfile"
            continue
        }

        $expected = Join-Path $clientRoot $localFile
        $packed = Join-Path $clientRoot ([string]$entry.url)
        if (-not (Test-Path $expected) -and -not (Test-Path $packed)) {
            Add-Failure "Missing asset reference: $localFile"
        }
    }
}

if (-not (Test-Path $catalogPath)) {
    Add-Failure "Client/assets/catalog-content.json missing"
} else {
    $catalog = Get-Content -Path $catalogPath -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($entry in @($catalog)) {
        $file = [string]$entry.file
        if ([string]::IsNullOrWhiteSpace($file)) {
            Add-Failure "Catalog entry without file"
            continue
        }

        $expected = Join-Path (Join-Path $clientRoot 'assets') $file
        if (-not (Test-Path $expected)) {
            Add-Failure "Missing catalog asset: $file"
        }
    }
}

$storeImages = @(Get-ChildItem -Path (Join-Path $clientRoot 'storeimages') -File -Recurse -ErrorAction SilentlyContinue)
if ($storeImages.Count -le 0) {
    Add-Failure "Client/storeimages has no image payloads"
}

if (-not (Test-Path $auditPath)) {
    Add-Failure "Docs/MISSING_ASSETS_AUDIT.md missing"
} else {
    $audit = Get-Content -Path $auditPath -Raw -Encoding UTF8
    foreach ($marker in @('BLOCKED_BY_CLIENT_VERSION', 'Store images', 'Boosted creature', 'Boosted boss')) {
        if ($audit -notmatch [regex]::Escape($marker)) {
            Add-Failure "Missing asset audit marker: $marker"
        }
    }
}

$report = [pscustomobject]@{
    status = if ($failures.Count -eq 0) { 'MISSING_ASSETS_AUDIT = PASS' } else { 'MISSING_ASSETS_AUDIT = FAIL' }
    clientAssetEntries = if (Test-Path $assetsJsonPath) { @((Get-Content -Path $assetsJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json).files).Count } else { 0 }
    catalogEntries = if (Test-Path $catalogPath) { @((Get-Content -Path $catalogPath -Raw -Encoding UTF8 | ConvertFrom-Json)).Count } else { 0 }
    storeImageFiles = $storeImages.Count
    failures = @($failures)
}

$report | ConvertTo-Json -Depth 8
if ($failures.Count -gt 0) { exit 1 }
