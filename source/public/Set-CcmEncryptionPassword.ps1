function Set-CcmEncryptionPassword {
    [CmdletBinding()]
    param(
        # The CCM server to operate against
        [string]$CcmEndpoint = "http://localhost",

        # The current credential for the account to change
        [System.Net.NetworkCredential]$Credential = @{
            userName = "ccmadmin"
            password = "123qwe"
        },

        # New encryption password to set
        [SecureString]$NewPassword,

        # Previous encryption password (unset on fresh install)
        [SecureString]$OldPassword = [SecureString]::new()
    )
    end {
        Update-CcmSettings -CcmEndpoint $CcmEndpoint -Credential $Credential -Settings @{
            encryption = @{
                oldPassphrase     = $OldPassword.ToPlainText()
                passphrase        = $NewPassword.ToPlainText()
                confirmPassphrase = $NewPassword.ToPlainText()
            }
        }
    }
}