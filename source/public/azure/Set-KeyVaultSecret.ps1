function Set-KeyVaultSecret {
    <#
        .Synopsis
            We (may) need to set secrets in the KeyVault
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$KeyVaultUrl,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$Name,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$Value
    )
    process {
        $Request = @{
            Uri         = "$($KeyVaultUrl.Trim('/'))/secrets/$($Name)?api-version=7.2"
            Method      = "Put"
            Body        = @{
                value = $Value
            } | ConvertTo-Json
            ContentType = "application/json"
            Headers     = @{
                Authorization = "Bearer $(Get-VmIdentityToken)"
            }
        }
        $null = Invoke-RestMethod @Request -UseBasicParsing
    }
}