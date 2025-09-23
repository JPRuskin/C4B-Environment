function Update-CcmSettings {
    [CmdletBinding()]
    param(
        # The CCM server to operate against
        [string]$CcmEndpoint = "http://localhost",

        # The current credential for the admin account
        [System.Net.NetworkCredential]$Credential = @{
            userName = "ccmadmin"
            password = "123qwe"
        },

        # A hashtable of settings to update. Only works two levels deep.
        [hashtable]$Settings
    )
    end {
        $Session = Get-CcmAuthenticatedSession -CcmEndpoint $CcmEndpoint -Credential $Credential

        # Get Current Settings
        $ServerSettings = (Invoke-RestMethod -Uri $CcmEndpoint/api/services/app/TenantSettings/GetAllSettings -WebSession $Session).result

        # Overwrite Settings via Hashtable
        foreach ($Heading in $Settings.Keys) {
            foreach ($Setting in $Settings[$Heading].Keys) {
                $ServerSettings.$Heading.$Setting = $Settings.$Heading.$Setting
            }
        }

        # PUT new Settings to CCM
        $SettingChange = @{
            Uri         = "$CcmEndpoint/api/services/app/TenantSettings/UpdateAllSettings"
            Method      = "PUT"
            ContentType = 'application/json; charset=utf-8'
            Body        = $ServerSettings | ConvertTo-Json
            WebSession  = $Session
        }
        $Result = Invoke-RestMethod @SettingChange -ErrorAction Stop

        if ($Result.success) {
            Write-Verbose "Updated Settings successfully."
        }
    }
}