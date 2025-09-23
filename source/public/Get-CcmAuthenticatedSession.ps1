function Get-CcmAuthenticatedSession {
    [CmdletBinding()]
    [OutputType([Microsoft.PowerShell.Commands.WebRequestSession])]
    param(
        # The CCM server to operate against
        [string]$CcmEndpoint = "http://localhost",

        # The current credential for the account to change
        [System.Net.NetworkCredential]$Credential = @{
            userName = "ccmadmin"
            password = "123qwe"
        }
    )
    end {
        # Wait-CCM -Url $CcmEndpoint

        Write-Verbose "Authenticating to CCM Web at '$($CcmEndpoint)'"
        $methodParams = @{
            Uri             = "$CcmEndpoint/Account/Login"
            Body            = @{
                usernameOrEmailAddress = $Credential.Username
                password               = $Credential.Password
            }
            ContentType     = 'application/x-www-form-urlencoded'
            Method          = "POST"
            SessionVariable = "Session"
        }
        try {
            $null = Invoke-WebRequest @methodParams -UseBasicParsing -ErrorAction Stop
        } catch {
            Write-Error "Failed to authenticate with '$($CcmEndpoint)': $($_)"
        }

        $Session
    }
}