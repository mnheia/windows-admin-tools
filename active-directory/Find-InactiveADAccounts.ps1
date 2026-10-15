# Report potentially inactive AD users and computers (approximate replicated logon timestamps).
param(
    [int]$InactiveDays = 90,
    [ValidateSet('Users','Computers','Both')][string]$Type = 'Both',
    [string]$SearchBase,
    [string]$CsvPath
)

Import-Module ActiveDirectory -ErrorAction Stop
$cutoff = (Get-Date).AddDays(-$InactiveDays)
$results = @()
if ($Type -in @('Users','Both')) {
    $query = @{Filter = 'Enabled -eq $true'; Properties = @('LastLogonDate','WhenCreated')}
    if ($SearchBase) { $query.SearchBase = $SearchBase }
    $results += Get-ADUser @query | Where-Object {
        ($_.LastLogonDate -and $_.LastLogonDate -lt $cutoff) -or
        (-not $_.LastLogonDate -and $_.WhenCreated -lt $cutoff)
    } | Select-Object @{n='Type';e={'User'}},Name,SamAccountName,LastLogonDate,WhenCreated
}
if ($Type -in @('Computers','Both')) {
    $query = @{Filter = 'Enabled -eq $true'; Properties = @('LastLogonDate','WhenCreated')}
    if ($SearchBase) { $query.SearchBase = $SearchBase }
    $results += Get-ADComputer @query | Where-Object {
        ($_.LastLogonDate -and $_.LastLogonDate -lt $cutoff) -or
        (-not $_.LastLogonDate -and $_.WhenCreated -lt $cutoff)
    } | Select-Object @{n='Type';e={'Computer'}},Name,SamAccountName,LastLogonDate,WhenCreated
}
$results = @($results | Sort-Object Type,Name)
$results | Format-Table -AutoSize
Write-Host "Potentially inactive accounts: $($results.Count)"
if ($CsvPath) { $results | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8 }
