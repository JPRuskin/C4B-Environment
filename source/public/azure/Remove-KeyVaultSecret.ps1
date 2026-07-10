function Remove-KeyVaultSecret {
    <#
        .Synopsis
            Deleted a Secret from an Azure Key Vault
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$KeyVaultUrl,

        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Name
    )
    process {
        $Request = @{
            Uri     = "$($KeyVaultUrl.Trim('/'))/secrets/$($Name)?api-version=7.3"
            Method  = "Delete"
            Headers = @{
                Authorization = "Bearer $(Get-VmIdentityToken)"
            }
        }
        (Invoke-RestMethod @Request -UseBasicParsing).Value
    }
}