function New-ServicePassword {
    <#
        .Synopsis
            Generates and returns a suitably secure password suited for support calls
    #>
    [CmdletBinding()]
    [OutputType([System.Security.SecureString])]
    param(
        [ValidateRange(1,128)]
        [int]$Length = 64,

        [char[]]$AvailableCharacters = @(
            # Specifically excluding $, `, ;, #, etc such that pasting
            # passwords into support scripts will be more predictable.
            "!%()*+,-./<=>?@[\]^_"
            48..57   # 0-9
            65..90   # A-Z
            97..122  # a-z
        ).ForEach{[char[]]$_}
    )
    end {
        $NewPassword = [System.Security.SecureString]::new()

        while ($NewPassword.Length -lt $Length) {
            $NewPassword.AppendChar(($AvailableCharacters | Get-Random))
        }

        $NewPassword
    }
}