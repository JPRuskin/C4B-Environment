function Copy-CertToStore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $Certificate
    )

    $location = [System.Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine
    $trustedCertStore = [System.Security.Cryptography.X509Certificates.X509Store]::new('TrustedPeople', $location)

    try {
        $trustedCertStore.Open('ReadWrite')
        $trustedCertStore.Add($Certificate)
    }
    finally {
        $trustedCertStore.Close()
        $trustedCertStore.Dispose()
    }
}