# Report AD passwords that expired within the last N days.
param(
    [int]$DaysAfterExpiry = 7,
    [string]$SearchBase,
    [string]$To,
    [string]$From,
    [string]$SmtpServer
)

Import-Module ActiveDirectory -ErrorAction Stop
$today = Get-Date
$properties = @('DisplayName', 'Enabled', 'PasswordNeverExpires', 'msDS-UserPasswordExpiryTimeComputed')
$params = @{ Filter = '*'; Properties = $properties }
if ($SearchBase) { $params.SearchBase = $SearchBase }

$users = Get-ADUser @params | Where-Object { $_.Enabled -and -not $_.PasswordNeverExpires }
$results = foreach ($user in $users) {
    $value = $user.'msDS-UserPasswordExpiryTimeComputed'
    if (-not $value -or $value -ge [DateTime]::MaxValue.ToFileTimeUtc()) { continue }
    $expiry = [DateTime]::FromFileTime($value)
    $days = ($today - $expiry).TotalDays
    if ($days -ge 0 -and $days -le $DaysAfterExpiry) {
        [pscustomobject]@{ User = $user.SamAccountName; Name = $user.DisplayName; Expired = $expiry; DaysAgo = [math]::Floor($days) }
    }
}

$results | Sort-Object Expired -Descending | Format-Table -AutoSize
if ($To -and $From -and $SmtpServer -and $results) {
    $message = $results | Sort-Object Expired -Descending | Out-String
    Send-MailMessage -To $To -From $From -SmtpServer $SmtpServer -Subject 'AD passwords expired' -Body $message -Encoding UTF8
}
