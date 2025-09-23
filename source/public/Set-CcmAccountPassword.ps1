function Set-CcmAccountPassword {
    <#
        .Synopsis
            Sets the password for a current CCM user

        .Notes
            Relies on the account not being set to reset-password-on-next-login, and not locked out.
    #>
    [CmdletBinding()]
    param(
        # The CCM server to operate against
        [string]$CcmEndpoint = "http://localhost",

        # The current credential for the account to change
        [System.Net.NetworkCredential]$Credential = @{
            userName = "ccmadmin"
            password = "123qwe"
        },

        # A Valid ConnectionString for the CCM Database
        [string]$ConnectionString,

        # The new password to set
        [Parameter(Mandatory)]
        [SecureString]$NewPassword
    )
    $NewCredential = [System.Net.NetworkCredential]::new($Credential.UserName, $NewPassword)

    if ($ConnectionString) {
        try {
            $Connection = [System.Data.SQLClient.SqlConnection]::new($ConnectionString)
            $Connection.Open()
            $Query = [System.Data.SQLClient.SqlCommand]::new(
                "UPDATE [dbo].[AbpUsers] SET ShouldChangePasswordOnNextLogin = 0, IsLockoutEnabled = 0 WHERE Name = @UserName and TenantId = '1'",
                $Connection
            )
            $null = $Query.Parameters.Add(
                [System.Data.SqlClient.SqlParameter]::new('UserName', $Credential.UserName)
            )
            $QueryResult = $Query.BeginExecuteReader()
            while (-not $QueryResult.isCompleted) {
                Write-Verbose "Waiting for SQL Query to return"
                Start-Sleep -Milliseconds 100
            }
            if ($QueryResult.isCompleted -and -not $QueryResult.IsFaulted) {
                Write-Verbose "Unset ShouldChangePasswordOnNextLogin for '$($Credential.Username)'"
            }
        } finally {
            $Query.Dispose()
            $Connection.Close()
            $Connection.Dispose()
        }
    }

    $Session = Get-CcmAuthenticatedSession -CcmEndpoint $CcmEndpoint -Credential $Credential

    Write-Verbose "Changing password for account '$($Credential.UserName)'"
    $resetParams = @{
        Uri         = "$CcmEndpoint/api/services/app/Profile/ChangePassword"
        Body        = @{
            CurrentPassword   = $Credential.Password
            NewPassword       = $NewCredential.Password
            NewPasswordRepeat = $NewCredential.Password
        } | ConvertTo-Json
        ContentType = 'application/json'
        Method      = "POST"
        WebSession  = $Session
    }
    $Result = Invoke-RestMethod @resetParams -UseBasicParsing

    if ($Result.Success -eq 'true') {
        Write-Verbose "Password for account '$($Credential.UserName)' was changed successfully."
    }
}