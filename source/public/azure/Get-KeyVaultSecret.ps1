function Get-KeyVaultSecret {
    <#
        .Synopsis
            We need to get secrets from the KeyVault
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
            Uri     = "$($KeyVaultUrl.Trim('/'))/secrets/$($Name)?api-version=2016-10-01"
            Method  = "Get"
            Headers = @{
                Authorization = "Bearer $(Get-VmIdentityToken)"
            }
        }
        (Invoke-RestMethod @Request -UseBasicParsing).Value
    }
}