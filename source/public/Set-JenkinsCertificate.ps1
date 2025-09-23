function Set-JenkinsCertificate {
    <#
        .Synopsis
            Updates a keystore and ensure Jenkins is configured to use an appropriate port and certificate for HTTPS access

        .Example
            Set-JenkinsCert -Thumbprint $Thumbprint

        .Notes
            Requires a Jenkins service restart after the changes have been made.
    #>
    [CmdletBinding()]
    param(
        # The thumbprint of the certificate to use
        [Parameter(Mandatory)]
        [String]$Thumbprint,

        # The port to have HTTPS available on
        [Parameter()]
        [uint16]$Port = 7443
    )

    $KeyStore = "C:\ProgramData\Jenkins\.jenkins\keystore.jks"
    $KeyTool = @(Convert-Path "C:\Program Files\Eclipse Adoptium\jre-*.*\bin\keytool.exe")[0]  # Using Temurin jre package keytool
    $Passkey = [System.Net.NetworkCredential]::new(
        "JksPassword",
        (New-ServicePassword -AvailableCharacters @(48..57 + 65..90 + 97..122))
    ).Password

    if (Test-Path $KeyStore) {
        Remove-Item $KeyStore -Force
    }

    # Generate the Keystore file
    try {
        $CertificatePath = Join-Path $env:Temp "$($Thumbprint).pfx"
        $CertificatePassword = [System.Net.NetworkCredential]::new(
            "TemporaryCertificatePassword",
            (New-ServicePassword)
        )

        # Temporarily export the certificate as a PFX
        $null = Get-ChildItem Cert:\LocalMachine\TrustedPeople\ | Where-Object {$_.Thumbprint -eq $Thumbprint} | Export-PfxCertificate -FilePath $CertificatePath -Password $CertificatePassword.SecurePassword

        # Using a job to hide improper non-output streams
        $Job = Start-Job {
            $CurrentAlias = ($($using:CertificatePassword.Password | & $using:KeyTool -list -v -storetype PKCS12 -keystore $using:CertificatePath -J"-Duser.language=en") -match "^Alias.*").Split(':')[1].Trim()

            $null = & $using:KeyTool -importkeystore -srckeystore $using:CertificatePath -srcstoretype PKCS12 -srcstorepass $using:CertificatePassword.Password -destkeystore $using:KeyStore -deststoretype JKS -alias $currentAlias -destalias jetty -deststorepass $using:Passkey
            $null = & $using:KeyTool -keypasswd -keystore $using:KeyStore -alias jetty -storepass $using:Passkey -keypass $using:CertificatePassword.Password -new $using:Passkey
        } | Wait-Job
        if ($Job.State -eq 'Failed') {
            $Job | Receive-Job
        } else {
            $Job | Remove-Job
        }
    } finally {
        # Clean up the exported certificate
        Remove-Item $CertificatePath
    }

    # Update the Jenkins Configuration
    $XmlPath = "C:\Program Files\Jenkins\jenkins.xml"
    [xml]$Xml = Get-Content $XmlPath
    @{
        httpPort              = -1
        httpsPort             = $Port
        httpsKeyStore         = $KeyStore
        httpsKeyStorePassword = $Passkey
    }.GetEnumerator().ForEach{
        if ($Xml.SelectSingleNode("/service/arguments")."#text" -notmatch [Regex]::Escape("--$($_.Key)=$($_.Value)")) {
            $Xml.SelectSingleNode("/service/arguments")."#text" = $Xml.SelectSingleNode("/service/arguments")."#text" -replace "\s*--$($_.Key)=.+?\b", ""
            $Xml.SelectSingleNode("/service/arguments")."#text" += " --$($_.Key)=$($_.Value)"
        }
    }
    $Xml.Save($XmlPath)

    if ((Get-Service Jenkins).Status -eq 'Running') {
        Restart-Service Jenkins
    }
}