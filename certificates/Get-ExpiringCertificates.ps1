<#
.SYNOPSIS
    List local machine certificates that will expire soon.

.NOTES
    Author: mnheia
    Copyright: (c) 2026 mnheia
    Repository: https://github.com/mnheia/windows-admin-tools
    License: GPL-3.0 (see LICENSE)
#>

param(
    [int]$DaysBeforeExpiry = 30,
    [string]$To,
    [string]$From,
    [string]$SmtpServer
)

$today = Get-Date
$limit = $today.AddDays($DaysBeforeExpiry)
$certs = Get-ChildItem Cert:\LocalMachine\My | Where-Object {
    $_.NotAfter -ge $today -and $_.NotAfter -le $limit
} | Sort-Object NotAfter

$report = $certs | Select-Object Subject, Thumbprint, NotAfter
$report | Format-Table -AutoSize

if ($To -and $From -and $SmtpServer -and $report) {
    $body = $report | Out-String
    Send-MailMessage -To $To -From $From -SmtpServer $SmtpServer `
        -Subject 'Certificate expiration notification' -Body $body -Encoding UTF8
}
