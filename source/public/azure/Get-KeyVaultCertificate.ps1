function Get-KeyVaultCertificate {
    <#
        .Synopsis
            Get a certificate from the KeyVault
    #>
    param(
        [Parameter(Mandatory)]
        [string]$KeyVaultUrl,

        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Name
    )
    process {
        $Request = @{
            Uri     = "$($KeyVaultUrl.Trim('/'))/certificates/$($Name)?api-version=7.3"
            Method  = "Get"
            Headers = @{
                Authorization = "Bearer $(Get-VmIdentityToken)"
            }
        }
        Invoke-RestMethod @Request -UseBasicParsing
    }
}