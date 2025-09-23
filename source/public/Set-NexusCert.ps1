function Set-NexusCert {
    [CmdletBinding()]
    param(
        # The thumbprint of the certificate to configure Nexus to use, from the LocalMachine\TrustedPeople store.
        [Parameter(Mandatory)]
        $Thumbprint,

        # The port to set Nexus to use for https.
        $Port = 8443
    )

    $KeyTool = "C:\ProgramData\nexus\jre\bin\keytool.exe"
    $KeyStorePath = 'C:\ProgramData\nexus\etc\ssl\keystore.jks'
    $KeystoreCredential = [System.Net.NetworkCredential]::new(
        "Keystore",
        (New-ServicePassword)
    )
    $TempCertPath = Join-Path $env:TEMP "$(New-Guid).pfx"

    try {
        # Temporarily export the certificate as a PFX
        Get-ChildItem Cert:\LocalMachine\TrustedPeople\ | Where-Object { $_.Thumbprint -eq $Thumbprint } | Sort-Object | Select-Object -First 1 | Export-PfxCertificate -FilePath $TempCertPath -Password $KeystoreCredential.SecurePassword
        # TODO: Is this the right place for this? # Get-ChildItem -Path $TempCertPath | Import-PfxCertificate -CertStoreLocation Cert:\LocalMachine\My -Exportable -Password $KeystoreCredential.SecurePassword
        
        if (Test-Path $KeyStorePath) {
            Remove-Item $KeyStorePath -Force
        }

        # Using a job to hide improper non-output streams
        $Job = Start-Job {
            $string = ($using:KeystoreCredential.Password | & $using:KeyTool -list -v -keystore $using:TempCertPath -J"-Duser.language=en") -match '^Alias.*'
            $currentAlias = ($string -split ':')[1].Trim()
            & $using:KeyTool -importkeystore -srckeystore $using:TempCertPath -srcstoretype PKCS12 -srcstorepass $using:KeystoreCredential.Password -destkeystore $using:KeyStorePath -deststoretype JKS -alias $currentAlias -destalias jetty -deststorepass $using:KeystoreCredential.Password
            & $using:KeyTool -keypasswd -keystore $using:KeyStorePath -alias jetty -storepass $using:KeystoreCredential.Password -keypass $using:KeystoreCredential.Password -new $using:KeystoreCredential.Password
        } | Wait-Job
        if ($Job.State -eq 'Failed') {
            $Job | Receive-Job
        } else {
            $Job | Remove-Job
        }
    } finally {
        if (Test-Path $TempCertPath) {
            Remove-Item $TempCertPath -Force
        }
    }

    # Update the Nexus configuration
    $xmlPath = 'C:\ProgramData\nexus\etc\jetty\jetty-https.xml'
    [xml]$xml = Get-Content -Path 'C:\ProgramData\nexus\etc\jetty\jetty-https.xml'
    foreach ($entry in $xml.Configure.New.Where{ $_.id -match 'ssl' }.Set.Where{ $_.name -match 'password' }) {
        $entry.InnerText = $KeystoreCredential.Password
    }

    $xml.Save($xmlPath)

    $configPath = "C:\ProgramData\sonatype-work\nexus3\etc\nexus.properties"

    # Remove existing ssl config from the configuration
    (Get-Content $configPath) | Where-Object {$_ -notmatch "application-port-ssl="} | Set-Content $configPath

    # Ensure each line is added to the configuration
    @(
        'jetty.https.stsMaxAge=-1'
        "application-port-ssl=$Port"
        'nexus-args=${jetty.etc}/jetty.xml,${jetty.etc}/jetty-https.xml,${jetty.etc}/jetty-requestlog.xml'
    ) | ForEach-Object {
        if ((Get-Content -Raw $configPath) -notmatch [regex]::Escape($_)) {
            $_ | Add-Content -Path $configPath
        }
    }

    if ((Get-Service Nexus).Status -eq 'Running') {
        Restart-Service Nexus
    }
}