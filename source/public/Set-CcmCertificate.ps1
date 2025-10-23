function Set-CcmCertificate {
    <#
        .SYNOPSIS
            Certificate renewal script for Chocolatey Central Management(CCM)

        .DESCRIPTION
            This script will go through and renew the certificate association with both the Chocolatey Central Management Service and IIS Web hosted dashboard.

        .PARAMETER CertificateThumbprint
            Thumbprint value of the certificate you would like the Chocolatey Central Management Service and Web to run on.
            Please make sure the certificate is located in the Cert:\LocalMachine\TrustedPeople\ certificate store.

        .EXAMPLE
            PS> Set-CCMCertificate -Thumbprint 'Your_Certificate_Thumbprint_Value'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Alias("CertificateThumbprint")]
        [ArgumentCompleter({
                Get-ChildItem Cert:\LocalMachine\TrustedPeople, Cert:\LocalMachine\My | ForEach-Object {
                    [System.Management.Automation.CompletionResult]::new(
                        $_.Thumbprint,
                        $_.Thumbprint,
                        "ParameterValue",
                        $_.Thumbprint
                    )
                }
            })]
        [String]
        $Thumbprint
    )
    # Chocolatey Central Management Service
    if (Test-Path $env:ChocolateyInstall\lib\chocolatey-management-service) {
        Stop-Service chocolatey-central-management

        Write-Verbose "Updating Thumpbprint in AppSettings for Chocolatey-Central-Management Service"
        $jsonData = Get-Content $env:ChocolateyInstall\lib\chocolatey-management-service\tools\service\appsettings.json | ConvertFrom-Json
        $jsonData.CertificateThumbprint = $CertificateThumbprint
        $jsonData | ConvertTo-Json | Set-Content $env:chocolateyInstall\lib\chocolatey-management-service\tools\service\appsettings.json

        Start-Service chocolatey-central-management
    }

    # Chocolatey Central Management Web
    if (Test-Path $env:ChocolateyInstall\lib\chocolatey-management-web) {
        Write-Verbose "Removing existing bindings"
        netsh http delete sslcert ipport=0.0.0.0:443 | Write-Verbose

        Write-Verbose "Adding new IIS binding to Chocolatey Central Management"
        $guid = [Guid]::NewGuid().ToString("B")
        netsh http add sslcert ipport=0.0.0.0:443 certhash=$Thumbprint certstorename=TrustedPeople appid="$guid" | Write-Verbose
        Get-WebBinding -Name ChocolateyCentralManagement | Remove-WebBinding
        New-WebBinding -Name ChocolateyCentralManagement -Protocol https -Port 443 -SslFlags 0 -IpAddress '*'
    }
}