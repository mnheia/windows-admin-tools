# Quick health check for all domain controllers in the current domain.
param([int]$ReplicationWarningHours = 24)

Import-Module ActiveDirectory -ErrorAction Stop
$domain = Get-ADDomain
$controllers = @(Get-ADDomainController -Filter *)
$results = foreach ($dc in $controllers) {
    $name = $dc.HostName
    Write-Host "Checking $name..." -ForegroundColor Cyan
    $dns = $null
    try { $dns = @(Resolve-DnsName -Name $name -Type A -ErrorAction Stop).Count -gt 0 } catch { $dns = $false }
    $ldap = Test-NetConnection -ComputerName $name -Port 389 -InformationLevel Quiet -WarningAction SilentlyContinue
    $sysvol = Test-Path "\\$name\SYSVOL"
    $netlogon = Test-Path "\\$name\NETLOGON"
    $replication = 'OK'
    try {
        $partners = @(Get-ADReplicationPartnerMetadata -Target $name -Partition * -ErrorAction Stop)
        if ($partners | Where-Object { $_.LastReplicationResult -ne 0 }) {
            $replication = 'FAILED'
        } elseif ($partners | Where-Object { $_.LastReplicationSuccess -lt (Get-Date).AddHours(-$ReplicationWarningHours) }) {
            $replication = 'STALE'
        } elseif ($controllers.Count -gt 1 -and $partners.Count -eq 0) {
            $replication = 'UNKNOWN'
        }
    } catch { $replication = 'ERROR' }
    [pscustomobject]@{
        Controller = $name; DNS = $dns; LDAP = $ldap
        SYSVOL = $sysvol; NETLOGON = $netlogon; Replication = $replication
    }
}
$results | Format-Table -AutoSize
Write-Host ("Domain: {0} | PDC: {1} | RID: {2} | Infrastructure: {3}" -f $domain.DNSRoot, $domain.PDCEmulator, $domain.RIDMaster, $domain.InfrastructureMaster)
$forest = Get-ADForest
Write-Host ("Schema: {0} | Domain naming: {1}" -f $forest.SchemaMaster, $forest.DomainNamingMaster)
if ($results | Where-Object { -not $_.DNS -or -not $_.LDAP -or -not $_.SYSVOL -or -not $_.NETLOGON -or $_.Replication -ne 'OK' }) { exit 1 }
