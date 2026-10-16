<#
.SYNOPSIS
    Renew and optionally copy an offline CA CRL.

.NOTES
    Author: mnheia
    Copyright: (c) 2026 mnheia
    Repository: https://github.com/mnheia/windows-admin-tools
    License: GPL-3.0 (see LICENSE)
#>

param(
    [Parameter(Mandatory)][string]$CrlPath,
    [string]$CopyTo,
    [int]$RenewAfterDays = 180,
    [switch]$Renew
)

$crl = Get-Item -LiteralPath $CrlPath -ErrorAction Stop
$age = ((Get-Date) - $crl.LastWriteTime).TotalDays
Write-Host "CRL: $CrlPath ($([math]::Floor($age)) days old)"
if (-not $Renew) { return }
if ($age -lt $RenewAfterDays) { Write-Host 'CRL is not old enough for scheduled renewal.'; return }

$backup = Join-Path $crl.DirectoryName ('backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Path $backup -Force | Out-Null
Copy-Item -LiteralPath $CrlPath -Destination $backup -ErrorAction Stop

& certutil.exe -crl
if ($LASTEXITCODE -ne 0) { throw 'CRL renewal failed.' }
$newCrl = Get-Item -LiteralPath $CrlPath -ErrorAction Stop
if ($newCrl.LastWriteTime -le $crl.LastWriteTime) { throw 'CRL file was not updated.' }
if ($CopyTo) {
    Copy-Item -LiteralPath $CrlPath -Destination $CopyTo -Force -ErrorAction Stop
    $target = if (Test-Path $CopyTo -PathType Container) { Join-Path $CopyTo $newCrl.Name } else { $CopyTo }
    if ((Get-FileHash $CrlPath).Hash -ne (Get-FileHash $target).Hash) { throw 'CRL copy hash mismatch.' }
}
Write-Host 'CRL renewed successfully.'
