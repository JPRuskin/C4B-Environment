Function New-QuickstartReadme {
    <#
.SYNOPSIS
Generates a desktop README file containing service information for all services provisioned as part of the Quickstart Guide.
.PARAMETER HostName
The host name of the C4B instance.
.EXAMPLE
./New-QuickstartReadme.ps1
.EXAMPLE
./New-QuickstartReadme.ps1 -HostName c4b.example.com
#>
    [CmdletBinding()]
    param()
    process {
        try {
            $Data = Get-ChocoEnvironmentProperty
        } catch {
            Write-Error "Unable to read stored values. Ensure the Quickstart Guide has been completed."
        }

        Copy-Item $PSScriptRoot\data\ReadmeTemplate.html.j2 -Destination $env:Public\Desktop\Readme.html -Force

        # Working around the existing j2 template, so we can keep them roughly in sync
        Invoke-TextReplacementInFile -Path $env:Public\Desktop\Readme.html -Replacement @{
            # CCM Values
            "{{ ccm_fqdn .*?}}" = ([uri]$Data.CCMWebPortal).DnsSafeHost
            "{{ ccm_port .*?}}"     = ([uri]$Data.CCMWebPortal).Port
            "{{ ccm_password .*?}}" = [System.Web.HttpUtility]::HtmlEncode($Data.CCMCredential.Password.ToPlainText())

            # Chocolatey Configuration Values
            "{{ ccm_encryption_password .*?}}" = [System.Web.HttpUtility]::HtmlEncode($Data.CCMEncryptionPassword.ToPlainText())
            "{{ ccm_client_salt .*?}}" = [System.Web.HttpUtility]::HtmlEncode($Data.ClientSalt.ToPlainText())
            "{{ ccm_service_salt .*?}}" = [System.Web.HttpUtility]::HtmlEncode($Data.ServiceSalt.ToPlainText())
            "{{ chocouser_password .*?}}" = [System.Web.HttpUtility]::HtmlEncode($Data.NexusCredential.Password.ToPlainText())

            # Nexus Values
            "{{ nexus_fqdn .*?}}" = ([uri]$Data.NexusUri).DnsSafeHost
            "{{ nexus_port .*?}}" = ([uri]$Data.NexusUri).Port
            "{{ nexus_password .*?}}" = [System.Web.HttpUtility]::HtmlEncode($Data.NexusCredential.Password.ToPlainText())
            "{{ lookup\('file', 'credentials\/nexus_apikey'\) .*?}}" = $Data.NugetApiKey.ToPlainText()

            "{{ nexus_client_username .*?}}" = 'chocouser'
            "{{ nexus_client_password .*?}}" = [System.Web.HttpUtility]::HtmlEncode($Data.ChocoUserPassword.ToPlainText())

            "{{ nexus_packager_username .*?}}" = $Data.PackageUploadCredential.Username
            "{{ nexus_packager_password .*?}}" = [System.Web.HttpUtility]::HtmlEncode($Data.PackageUploadCredential.Password.ToPlainText())

            # Jenkins Values
            "{{ jenkins_fqdn .*?}}" = ([uri]$Data.JenkinsUri).DnsSafeHost
            "{{ jenkins_port .*?}}" = ([uri]$Data.JenkinsUri).Port
            "{{ jenkins_password .*?}}" = [System.Web.HttpUtility]::HtmlEncode($Data.JenkinsCredential.Password.ToPlainText())
        }
    }
}