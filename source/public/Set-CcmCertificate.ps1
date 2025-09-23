function Set-CcmCertificate {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [String]
        $CertificateThumbprint
    )

    process {
        Stop-Service chocolatey-central-management
        $jsonData = Get-Content $env:ChocolateyInstall\lib\chocolatey-management-service\tools\service\appsettings.json | ConvertFrom-Json
        $jsonData.CertificateThumbprint = $CertificateThumbprint
        $jsonData | ConvertTo-Json | Set-Content $env:chocolateyInstall\lib\chocolatey-management-service\tools\service\appsettings.json
        Start-Service chocolatey-central-management
    }
}