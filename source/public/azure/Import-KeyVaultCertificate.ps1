function Import-KeyVaultCertificate {
    <#
        .Synopsis
            Add an existing certificate to the KeyVault
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$KeyVaultUrl,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$Name,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$Value,

        [Parameter(ValueFromPipelineByPropertyName)]
        [securestring]$Password
    )
    process {
        $Body = @{
            value = $Value
        }
        if ($null -ne $Password) {
            $Body['pwd'] = $Password.ToPlainText()
        }
        $Request = @{
            Uri         = "$($KeyVaultUrl.Trim('/'))/certificates/$($Name)/import?api-version=7.3"
            Method      = "Post"
            Body        = $Body | ConvertTo-Json
            ContentType = "application/json"
            Headers     = @{
                Authorization = "Bearer $(Get-VmIdentityToken)"
            }
        }
        $null = Invoke-RestMethod @Request -UseBasicParsing
    }
}