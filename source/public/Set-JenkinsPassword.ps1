function Set-JenkinsPassword {
    <#
        .Synopsis
            Sets the password for a Jenkins user.
        .Example
            Set-JenkinsPassword -UserName 'admin' -NewPassword $JenkinsCred.Password
            # Sets the password to a known value
        .Example
            Set-JenkinsPassword -Credential $JenkinsCred
            # Sets the password to a known value
        .Example
            $JenkinsCred = Set-JenkinsPassword -UserName 'admin' -NewPassword $(New-ServicePassword) -PassThru
            # Sets the password and stores a credential object in $JenkinsCred.
        .Notes
            This probably will not work for federated and other non-standard accounts.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Split')]
    param(
        # The credential of the user to try and set.
        [Parameter(ParameterSetName = 'Cred', Mandatory, Position=0)]
        [PSCredential]$Credential = [PSCredential]::new($UserName, $NewPassword),

        # The name of the user to forcibly set the password for.
        [Parameter(ParameterSetName = 'Split', Mandatory, Position=0)]
        [string]$UserName = $Credential.UserName,

        # The password to set for the user.
        [Parameter(ParameterSetName = 'Split', Mandatory, Position=1)]
        [SecureString]$NewPassword = $Credential.Password,

        # If set, passes the credential object for the user back.
        [Parameter()]
        [switch]$PassThru,

        # The path to the Jenkins data directory.
        [Parameter()]
        $JenkinsHome = (Join-Path $env:ProgramData "Jenkins\.jenkins")
    )
    try {
        $BCryptDllPath = Get-BcryptDll -ErrorAction Stop
        Add-Type -Path $BCryptDllPath -ErrorAction Stop
    } catch {
        Write-Error "Could not get Bcrypt DLL:`n$_"
    }

    $UserConfigPath = Resolve-Path "$JenkinsHome\users\$($UserName)_*\config.xml"
    if ($UserConfigPath.Count -ne 1) {
        Write-Error "$($UserConfigPath.Count) user config file(s) were found for user '$($UserName)'"
    }
    Write-Verbose "Updating '$($UserConfigPath)'"

    # Can't load as XML document as file is XML v1.1
    (Get-Content $UserConfigPath) -replace '<passwordHash>#jbcrypt:.*</passwordHash>',
    "<passwordHash>#jbcrypt:$(
        [bcrypt.net.bcrypt]::hashpassword(
            ([System.Net.NetworkCredential]$Credential).Password,
            ([bcrypt.net.bcrypt]::generatesalt(15))
        )
    )</passwordHash>" |
    Set-Content $UserConfigPath -Force

    if ($PassThru) {
        $Credential
    }
}