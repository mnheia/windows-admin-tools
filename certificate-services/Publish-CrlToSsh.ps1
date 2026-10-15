# Upload CRL files to a remote server with PuTTY PSCP and SSH key authentication.
param(
    [Parameter(Mandatory)][string]$CrlDirectory,
    [Parameter(Mandatory)][string[]]$CrlNames,
    [Parameter(Mandatory)][string]$HostName,
    [Parameter(Mandatory)][string]$UserName,
    [Parameter(Mandatory)][string]$PrivateKey,
    [Parameter(Mandatory)][string]$HostKey,
    [string]$RemoteDirectory = '/crl',
    [int]$Port = 22,
    [string]$Pscp = 'pscp.exe'
)

foreach ($name in $CrlNames) {
    $source = Join-Path $CrlDirectory $name
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "CRL missing: $source" }
    & $Pscp -batch -i $PrivateKey -hostkey $HostKey -P $Port `
        $source "${UserName}@${HostName}:$RemoteDirectory/"
    if ($LASTEXITCODE -ne 0) { throw "Transfer failed: $name" }
    Write-Host "Transferred: $name"
}
