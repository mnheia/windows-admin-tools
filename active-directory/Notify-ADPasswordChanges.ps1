# Notify users when their AD password was changed recently.
param(
    [int]$MinutesChanged = 15,
    [string]$SearchBase,
    [string]$From,
    [string]$SmtpServer
)

Import-Module ActiveDirectory -ErrorAction Stop
$since = (Get-Date).AddMinutes(-$MinutesChanged)
$params = @{ Filter = '*'; Properties = @('Mail', 'DisplayName', 'PasswordLastSet') }
if ($SearchBase) { $params.SearchBase = $SearchBase }

$users = Get-ADUser @params | Where-Object { $_.PasswordLastSet -ge $since -and $_.Mail }
foreach ($user in $users) {
    $lastSet = $user.PasswordLastSet.ToString('dd.MM.yyyy HH:mm:ss')
    Write-Host "$($user.SamAccountName): password set at $lastSet"

    if ($From -and $SmtpServer) {
        $body = @"
<p>(English below)</p>
<p>Vaše domensko geslo je bilo spremenjeno $lastSet.</p>
<p>Če gesla niste spremenili vi, o tem nemudoma obvestite skrbnika sistema.</p>
<hr>
<p>Your domain password was changed on $lastSet.</p>
<p>If you did not change it, contact your system administrator immediately.</p>
"@
        Send-MailMessage -To $user.Mail -From $From -SmtpServer $SmtpServer `
            -Subject 'Domain password changed / Domensko geslo spremenjeno' `
            -Body $body -BodyAsHtml -Encoding UTF8
    }
}
