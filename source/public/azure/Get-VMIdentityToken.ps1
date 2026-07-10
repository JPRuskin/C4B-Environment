function Get-VmIdentityToken {
    <#
        .Synopsis
            In order to access the KeyVault secrets, we need a token
    #>
    [CmdletBinding()]
    param()
    end {
        if (-not $script:VmManagedIdentity -or $script:VmManagedIdentity.expires_on -lt 5) {
            # https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/how-to-use-vm-token#get-a-token-using-http
            $Request = @{
                Uri     = 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net'
                Method  = 'GET'
                Headers = @{
                    Metadata = "true"
                }
            }
            $script:VmManagedIdentity = Invoke-RestMethod @Request -UseBasicParsing
        }

        $script:VmManagedIdentity.access_token
    }
}