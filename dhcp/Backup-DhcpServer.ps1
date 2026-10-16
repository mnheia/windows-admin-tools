<#
.SYNOPSIS
    Back up a Windows DHCP server database.

.NOTES
    Author: mnheia
    Copyright: (c) 2026 mnheia
    Repository: https://github.com/mnheia/windows-admin-tools
    License: GPL-3.0 (see LICENSE)
#>

param(
    [Parameter(Mandatory)][string]$ComputerName,
    [Parameter(Mandatory)][string]$BackupRoot
)

Import-Module DhcpServer -ErrorAction Stop
$date = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupPath = Join-Path $BackupRoot $date

# The path is interpreted on the DHCP SERVER, including for remote backups.
Backup-DhcpServer -ComputerName $ComputerName -Path $backupPath -ErrorAction Stop
Write-Host "DHCP backup created on $ComputerName at $backupPath"
