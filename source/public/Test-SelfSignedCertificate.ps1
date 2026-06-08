function Test-SelfSignedCertificate {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        $Certificate = (Get-ChildItem -Path Cert:\LocalMachine\TrustedPeople | Where-Object { $_.FriendlyName -eq $SubjectWithoutCn })
    )
    process {
        $Certificate.Subject -eq $Certificate.Issuer
    }
}