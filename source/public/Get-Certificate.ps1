function Get-Certificate {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Thumbprint,

        [Parameter()]
        [string]
        $Subject
    )

    $filter = if ($Thumbprint) {
        { $_.Thumbprint -eq $Thumbprint }
    }
    else {
        { $_.Subject -like "CN=$Subject" }
    }

    $cert = Get-ChildItem -Path Cert:\LocalMachine\My, Cert:\LocalMachine\TrustedPeople |
    Where-Object $filter -ErrorAction Stop |
    Select-Object -First 1

    if ($null -eq $cert) {
        throw "Certificate either not found, or other issue arose."
    }
    else {
        Write-Host "Certification validation passed" -ForegroundColor Green
        $cert
    }
}