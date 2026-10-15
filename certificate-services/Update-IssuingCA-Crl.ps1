# Renew an issuing CA CRL and copy CRLs to a publication folder.
param(
    [Parameter(Mandatory)][string]$CrlPath,
    [Parameter(Mandatory)][string]$PublishDirectory,
    [string[]]$AdditionalCrlPaths = @(),
    [int]$RenewAfterDays = 15,
    [switch]$Renew
)

$crl = Get-Item -LiteralPath $CrlPath -ErrorAction Stop
$age = ((Get-Date) - $crl.LastWriteTime).TotalDays
if ($Renew -and $age -ge $RenewAfterDays) {
    $backup = Join-Path $crl.DirectoryName ('backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
    New-Item -Path $backup -ItemType Directory -Force | Out-Null
    Copy-Item -LiteralPath $CrlPath -Destination $backup -ErrorAction Stop
    & certutil.exe -crl
    if ($LASTEXITCODE -ne 0) { throw 'CRL renewal failed.' }
    if ((Get-Item $CrlPath).LastWriteTime -le $crl.LastWriteTime) { throw 'CRL file was not updated.' }
}

if (-not (Test-Path $PublishDirectory -PathType Container)) { throw "Publish directory missing: $PublishDirectory" }
foreach ($source in @($CrlPath) + $AdditionalCrlPaths) {
    $file = Get-Item -LiteralPath $source -ErrorAction Stop
    $dest = Join-Path $PublishDirectory $file.Name
    if ((Test-Path $dest) -and (Get-FileHash $source).Hash -eq (Get-FileHash $dest).Hash) {
        Write-Host "Already current: $($file.Name)"
        continue
    }
    Copy-Item -LiteralPath $source -Destination $dest -Force -ErrorAction Stop
    if ((Get-FileHash $source).Hash -ne (Get-FileHash $dest).Hash) { throw "CRL copy failed: $dest" }
    Write-Host "Published: $dest"
}
