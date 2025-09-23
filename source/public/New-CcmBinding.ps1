function New-CcmBinding {
    [CmdletBinding()]
    param(
        [string]$Thumbprint
    )
    Write-Verbose "Adding new binding https://${SubjectWithoutCn} to Chocolatey Central Management"

    $guid = [Guid]::NewGuid().ToString("B")
    netsh http add sslcert ipport=0.0.0.0:443 certhash=$Thumbprint certstorename=TrustedPeople appid="$guid" | Write-Verbose
    Get-WebBinding -Name ChocolateyCentralManagement | Remove-WebBinding
    New-WebBinding -Name ChocolateyCentralManagement -Protocol https -Port 443 -SslFlags 0 -IpAddress '*'
}