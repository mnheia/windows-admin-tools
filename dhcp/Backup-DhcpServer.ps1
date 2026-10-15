# Back up a Windows DHCP server database.
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
