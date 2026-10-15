Copyright (c) 2026, Mnheia <mnheia@gmail.com>

# windows-admin-tools

Short PowerShell scripts for common Active Directory, Group Policy, DHCP and Windows PKI tasks.
Run with Windows PowerShell 5.1 and the applicable AD/GroupPolicy/DHCPServer modules.

## Active Directory

- `active-directory/Get-ExpiringADPasswords.ps1` — lists passwords expiring within N days, using AD's computed expiry (including fine-grained policy).
- `active-directory/Get-ExpiredADPasswords.ps1` — finds passwords expired within N days.
- `active-directory/Notify-ADPasswordChanges.ps1` — notifies users whose password was recently set, when SMTP is configured.
- `active-directory/Find-OrphanedHomeDirectories.ps1` — compares home folder names with AD account names and optionally exports CSV. Verify results before deleting anything.

```powershell
.\active-directory\Get-ExpiringADPasswords.ps1 -DaysBeforeExpiry 14
.\active-directory\Find-OrphanedHomeDirectories.ps1 -HomeRoot '\\fileserver\homes' -CsvPath '.\orphans.csv'
```

## Group Policy and DHCP

- `group-policy/Backup-GroupPolicies.ps1` — dated GPO backup with an HTML report.
- `dhcp/Backup-DhcpServer.ps1` — dated DHCP Server configuration backup.

```powershell
.\group-policy\Backup-GroupPolicies.ps1 -OutputRoot 'D:\Backups\GPO'
.\dhcp\Backup-DhcpServer.ps1 -ComputerName 'dhcp.example.com' -BackupRoot 'D:\Backups\DHCP'
```

## Certificates and PKI

- `certificates/Get-ExpiringCertificates.ps1` — expiring machine certificate report.
- `certificate-services/Update-IssuingCA-Crl.ps1` — renew and publish an issuing CA CRL.
- `certificate-services/Update-OfflineCA-Crl.ps1` — renew an offline CA CRL and optionally copy it.
- `certificate-services/Publish-CrlToSsh.ps1` — copy CRLs using PSCP and SSH-key authentication.

```powershell
.\certificates\Get-ExpiringCertificates.ps1 -DaysBeforeExpiry 30
.\certificate-services\Update-OfflineCA-Crl.ps1 -CrlPath 'C:\Windows\System32\CertSrv\CertEnroll\RootCA.crl' -Renew
```

Configure your own SMTP relay, output locations and CA names via script parameters. The certificate renewal scripts use `-Renew` explicitly. For Task Scheduler you can invoke `.ps1` files directly using `powershell.exe -NoProfile -File <script> ...`.


## Additional health and audit scripts

- `active-directory/Test-ADHealth.ps1` — domain controller DNS, LDAP, SYSVOL, NETLOGON, replication and FSMO summary.
- `active-directory/Find-InactiveADAccounts.ps1` — approximate inactive users/computers based on replicated `LastLogonDate`.
- `certificate-services/Test-CAHealth.ps1` — local CA service and CRL `NextUpdate` checks; optional HTTP publication reachability.

```powershell
.\active-directory\Test-ADHealth.ps1
.\active-directory\Find-InactiveADAccounts.ps1 -InactiveDays 90 -Type Both
.\certificate-services\Test-CAHealth.ps1 -WarningDays 14
```

The checks do not modify AD, Exchange, certificates, or CA configuration. The CA script examines local CRLs; an optional URL check tests reachability, not the downloaded CRL's validity.

## Bugs

Please report issues at https://github.com/mnheia/windows-admin-tools/issues

## License

GPL-3.0; see `LICENSE`.
