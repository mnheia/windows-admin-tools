<#
.SYNOPSIS
    Find home directories with no matching Active Directory username.

.NOTES
    Author: mnheia
    Copyright: (c) 2026 mnheia
    Repository: https://github.com/mnheia/windows-admin-tools
    License: GPL-3.0 (see LICENSE)
#>

param(
    [Parameter(Mandatory)][string]$HomeRoot,
    [string]$SearchBase,
    [string]$CsvPath
)

Import-Module ActiveDirectory -ErrorAction Stop
if (-not (Test-Path $HomeRoot)) { throw "Directory not found: $HomeRoot" }
$params = @{ Filter = '*' }
if ($SearchBase) { $params.SearchBase = $SearchBase }
$users = @(Get-ADUser @params | Select-Object -ExpandProperty SamAccountName)

$names = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
foreach ($name in $users) { [void]$names.Add($name) }

$orphans = foreach ($folder in (Get-ChildItem -Path $HomeRoot -Directory)) {
    if ($names.Contains($folder.Name)) { continue }
    $size = 0L
    Get-ChildItem -LiteralPath $folder.FullName -File -Recurse -Force -ErrorAction SilentlyContinue |
        ForEach-Object { $size += $_.Length }
    [pscustomobject]@{
        Directory = $folder.FullName
        SizeGB = [math]::Round($size / 1GB, 2)
    }
}

$orphans | Format-Table -AutoSize
if ($CsvPath) { $orphans | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8 }
