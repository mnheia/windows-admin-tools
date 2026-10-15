# Report AD passwords expiring within the next N days.
param(
    [int]$DaysBeforeExpiry = 7,
    [string]$SearchBase,
    [string]$To,
    [string]$From,
    [string]$SmtpServer
)

Import-Module ActiveDirectory -ErrorAction Stop
$today = Get-Date
$properties = @('DisplayName', 'Mail', 'Enabled', 'PasswordNeverExpires', 'msDS-UserPasswordExpiryTimeComputed')
$params = @{ Filter = '*'; Properties = $properties }
if ($SearchBase) { $params.SearchBase = $SearchBase }

$users = Get-ADUser @params | Where-Object { $_.Enabled -and -not $_.PasswordNeverExpires }
$results = foreach ($user in $users) {
    $value = $user.'msDS-UserPasswordExpiryTimeComputed'
    if (-not $value -or $value -ge [DateTime]::MaxValue.ToFileTimeUtc()) { continue }
    $expiry = [DateTime]::FromFileTime($value)
    $days = ($expiry - $today).TotalDays
    if ($days -ge 0 -and $days -le $DaysBeforeExpiry) {
        [pscustomobject]@{ User = $user.SamAccountName; Name = $user.DisplayName; Expires = $expiry; DaysLeft = [math]::Ceiling($days) }
    }
}

$results | Sort-Object Expires | Format-Table -AutoSize
if ($To -and $From -and $SmtpServer -and $results) {
    $message = $results | Sort-Object Expires | Out-String
    Send-MailMessage -To $To -From $From -SmtpServer $SmtpServer -Subject 'AD passwords expiring soon' -Body $message -Encoding UTF8
}
