function Test-SelfSignedCertificate {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        $Certificate = (Get-ChildItem -Path Cert:LocalMachine\My | Where-Object { $_.FriendlyName -eq $SubjectWithoutCn })
    )
    process {
        $Certificate.Subject -eq $Certificate.Issuer
    }
}