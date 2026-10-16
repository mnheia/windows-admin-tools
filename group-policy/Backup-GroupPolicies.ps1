<#
.SYNOPSIS
    Backup all Group Policy Objects and create an HTML report.

.NOTES
    Author: mnheia
    Copyright: (c) 2026 mnheia
    Repository: https://github.com/mnheia/windows-admin-tools
    License: GPL-3.0 (see LICENSE)
#>

param(
    [string]$OutputRoot = 'C:\GPO-Backup',
    [string]$Domain,
    [string]$Server
)

Import-Module GroupPolicy -ErrorAction Stop
$date = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupPath = Join-Path $OutputRoot $date
New-Item -Path $backupPath -ItemType Directory -Force | Out-Null

$params = @{ All = $true; Path = $backupPath }
if ($Domain) { $params.Domain = $Domain }
if ($Server) { $params.Server = $Server }
Backup-GPO @params

$reportPath = Join-Path $OutputRoot "GPOReport-$date.html"
$params = @{ All = $true; ReportType = 'HTML'; Path = $reportPath }
if ($Domain) { $params.Domain = $Domain }
if ($Server) { $params.Server = $Server }
Get-GPOReport @params

Write-Host "Backup: $backupPath"
Write-Host "Report: $reportPath"
