function Test-CertificateDomain {
    param(
        [Parameter(Mandatory)]
        [string]$Thumbprint
    )
    # Check the certificate exists
    if (-not ($Certificate = Get-Item Cert:\LocalMachine\TrustedPeople\$Thumbprint)) {
        throw "Certificate could not be found in Cert:\LocalMachine\TrustedPeople\. Please ensure it is is present, and try again."
    }

    # Check that we have a domain for it
    $matcher = '^CN\s?=\s?(?<Subject>[^,\s]+)'

    if (-not ($CertificateDnsName = Get-ChocoEnvironmentProperty CertSubject) -and ($Certificate.Subject -match '^CN\s*=\s*\*')) {
        $null = $Certificate.Subject -match $matcher
        $CertificateDnsName = if ($Matches.Subject.StartsWith('*')) {
            # This is a wildcard cert, we need to prompt for the intended CertificateDnsName
            while ($CertificateDnsName -notlike $Matches.Subject) {
                $CertificateDnsName = Read-Host -Prompt "$(if ($CertificateDnsName) {"'$($CertificateDnsName)' is not a subdomain of '$($Matches.Subject)'. "})Please provide an FQDN to use with the certificate '$($Matches.Subject)'"
            }
            $CertificateDnsName
        } else {
            $Matches.Subject
        }
    } elseif ($Certificate.Subject -match $matcher -and -not $CertificateDnsName) {
        $CertificateDnsName = $Matches.Subject
    } elseif ($CertificateDnsName) {
        # We have a pre-existing domain to use
    } else {
        Write-Error "The certificate '$($Certificate.Subject)' ($Thumbprint) could not be identified."
        return $false
    }

    if ($CertificateDnsName) {
        Set-ChocoEnvironmentProperty CertSubject $CertificateDnsName
    }

    $true
}