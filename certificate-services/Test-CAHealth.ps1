<#
.SYNOPSIS
    Check local AD CS service and CRL validity, optionally including a published CRL.

.NOTES
    Author: mnheia
    Copyright: (c) 2026 mnheia
    Repository: https://github.com/mnheia/windows-admin-tools
    License: GPL-3.0 (see LICENSE)
#>

param(
    [string]$CrlDirectory = "$env:windir\System32\CertSrv\CertEnroll",
    [string]$PublishedCrlUrl,
    [int]$WarningDays = 14
)

$service = Get-Service CertSvc -ErrorAction SilentlyContinue
if ($service) { Write-Host "Certificate Services: $($service.Status)" }
else { Write-Warning 'CertSvc not found on this machine.' }

$files = @(Get-ChildItem -Path $CrlDirectory -Filter '*.crl' -File -ErrorAction SilentlyContinue)
if (-not $files.Count) { Write-Warning "No CRL files found in $CrlDirectory" }
$results = foreach ($file in $files) {
    $output = & certutil.exe -dump $file.FullName 2>&1
    $line = $output | Where-Object { $_ -match 'NextUpdate:' } | Select-Object -First 1
    $next = $null
    if ($line -and $line -match 'NextUpdate:\s*(.+)$') {
        $parsed = [datetime]::MinValue
        if ([datetime]::TryParse($matches[1].Trim(), [ref]$parsed)) { $next = $parsed }
    }
    $remaining = if ($next) { [math]::Floor(($next - (Get-Date)).TotalDays) } else { $null }
    [pscustomobject]@{
        CRL = $file.Name; NextUpdate = $next; DaysLeft = $remaining
        Status = if ($null -eq $remaining) {'UNKNOWN'} elseif ($remaining -lt 0) {'EXPIRED'} elseif ($remaining -le $WarningDays) {'WARNING'} else {'OK'}
    }
}
$results | Format-Table -AutoSize
if ($PublishedCrlUrl) {
    try {
        $response = Invoke-WebRequest -Uri $PublishedCrlUrl -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
        Write-Host "Published CRL HTTP status: $($response.StatusCode)"
    } catch { Write-Warning "Cannot retrieve published CRL: $_" }
}
if ($service -and $service.Status -ne 'Running') { exit 1 }
if ($results | Where-Object { $_.Status -ne 'OK' }) { exit 1 }
if (-not $files.Count) { exit 1 }
