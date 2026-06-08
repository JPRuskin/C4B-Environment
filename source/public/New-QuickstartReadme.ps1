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

        switch ($Data.PSObject.Properties.Name) {
            "CCMWebPortal" {
                Write-Verbose "Adding CCM"
                $TableElements = @"
    <tr>
        <td><img src="https://{{ ccm_fqdn }}:{{ ccm_port }}/favicon.ico" class="logo"></td>
        <td>Chocolatey Central Management</td>
        <td><a href="https://{{ ccm_fqdn }}:{{ ccm_port }}">{{ ccm_fqdn }}:{{ ccm_port }}</a></td>
        <td>ccmadmin</td>
        <td><a href="#" class="strip-decoration" onclick="CopyToClipboard('ccmpw');return false;"><div id="ccmpw" class="pw blurry-text">{{ ccm_password | e }}</div></a></td>
    </tr>
"@
            }
            "ProGetUri" {
                Write-Verbose "Adding ProGet"
                $TableElements = @"
    <tr>
        <td><img src="https://{{ proget_fqdn }}:{{ proget_port }}/favicon.ico" class="logo"></td>
        <td>ProGet</td>
        <td><a href="https://{{ proget_fqdn }}:{{ proget_port }}">{{ proget_fqdn }}:{{ proget_port }}</a></td>
        <td>admin</td>
        <td><a href="#" class="strip-decoration" onclick="CopyToClipboard('progetpw');return false;"><div id="progetpw" class="pw blurry-text">{{ proget_password | e }}</div></a></td>
    </tr>
"@
            }
            "NexusUri" {
                Write-Verbose "Adding Nexus"
                $TableElements = @"
    <tr>
        <td rowspan="2"><img src="https://{{ nexus_fqdn }}:{{ nexus_port }}/favicon.ico" class="logo"></td><td rowspan="2">Nexus</td>
        <td rowspan="2"><a href="https://{{ nexus_fqdn }}:{{ nexus_port }}">{{ nexus_fqdn }}:{{ nexus_port }}</a></td>
        <td>admin</td>
        <td><a href="#" class="strip-decoration" onclick="CopyToClipboard('nexuspw');return false;"><div id="nexuspw" class="pw blurry-text">{{ nexus_password | e }}</div></a></td>
    </tr>
    <tr>
        <td>{{ nexus_client_username }}</td>
        <td><a href="#" class="strip-decoration" onclick="CopyToClipboard('nexusclientpw');return false;"><div id="nexusclientpw" class="pw blurry-text">{{ nexus_client_password | e }}</div></a></td>
    </tr>
"@
            }
            "PowerShellUniversalUri" {
                Write-Verbose "Adding PowerShell Universal"
                $TableElements = @"
    <tr>
        <td><img src="https://{{ psu_fqdn }}:{{ psu_port }}/favicon.ico" class="logo"></td>
        <td>PowerShell Universal</td>
        <td><a href="https://{{ psu_fqdn }}:{{ psu_port }}">{{ psu_fqdn }}:{{ psu_port }}</a></td>
        <td>admin</td>
        <td><a href="#" class="strip-decoration" onclick="CopyToClipboard('psupw');return false;"><div id="psupw" class="pw blurry-text">{{ psu_password | e }}</div></a></td>
    </tr>
"@
                $GettingStartedElements = '<li><a href="https://{{ psu_fqdn }}:{{ psu_port }}/choco/internalize">Internalize some new packages</a> with PowerShell Universal</li>'
            }
            "JenkinsUri" {
                Write-Verbose "Adding Jenkins"
                $TableElements = @"
    <tr>
        <td><img src="https://{{ jenkins_fqdn }}:{{ jenkins_port }}/favicon.ico" class="logo"></td>
        <td>Jenkins</td>
        <td><a href="https://{{ jenkins_fqdn }}:{{ jenkins_port }}">{{ jenkins_fqdn }}:{{ jenkins_port }}</a></td>
        <td>admin</td>
        <td><a href="#" class="strip-decoration" onclick="CopyToClipboard('jenkinspw');return false;"><div id="jenkinspw" class="pw blurry-text">{{ jenkins_password | e }}</div></a></td>
    </tr>
"@
                $GettingStartedElements = '<li><a href="https://{{ jenkins_fqdn }}:{{ jenkins_port }}/job/Internalize%20packages%20from%20the%20Community%20Repository/build?delay=0sec">Internalize some new packages</a> with Jenkins</li>'
            }
        }

        Invoke-TextReplacementInFile -Path $env:Public\Desktop\Readme.html -Replacement @{
            # Add the expected table elements
            "{{ table_elements }}"                                   = $TableElements
            "{{ getting_started_list }}"                             = $GettingStartedElements

            # CCM Values
            "{{ ccm_fqdn .*?}}"                                      = if ($Data.CCMWebPortal) { ([uri]$Data.CCMWebPortal).DnsSafeHost } else { "" }
            "{{ ccm_port .*?}}"                                      = if ($Data.CCMWebPortal) { ([uri]$Data.CCMWebPortal).Port } else { "" }
            "{{ ccm_password .*?}}"                                  = if ($Data.CCMCredential) { [System.Web.HttpUtility]::HtmlEncode($Data.CCMCredential.Password.ToPlainText()) } else { "" }

            # Chocolatey Configuration Values
            "{{ ccm_encryption_password .*?}}"                       = if ($Data.CCMEncryptionPassword) { [System.Web.HttpUtility]::HtmlEncode($Data.CCMEncryptionPassword.ToPlainText()) } else { "" }
            "{{ ccm_client_salt .*?}}"                               = if ($Data.ClientSalt) { [System.Web.HttpUtility]::HtmlEncode($Data.ClientSalt.ToPlainText()) } else { "" }
            "{{ ccm_service_salt .*?}}"                              = if ($Data.ServiceSalt) { [System.Web.HttpUtility]::HtmlEncode($Data.ServiceSalt.ToPlainText()) } else { "" }
            "{{ chocouser_password .*?}}"                            = if ($Data.NexusCredential) {
                [System.Web.HttpUtility]::HtmlEncode($Data.NexusCredential.Password.ToPlainText())
            } elseif ($Data.ProGetUri) {
                [System.Web.HttpUtility]::HtmlEncode($Data.ChocoUserPassword)
            } else { "" }

            # ProGet Values
            "{{ proget_fqdn .*?}}"                                   = if ($Data.ProGetUri) { ([uri]$Data.ProGetUri).DnsSafeHost } else { "" }
            "{{ proget_port .*?}}"                                   = if ($Data.ProGetUri) { ([uri]$Data.ProGetUri).Port } else { "" }
            "{{ proget_password .*?}}"                               = if ($Data.ProGetCredential) { [System.Web.HttpUtility]::HtmlEncode($Data.ProGetCredential.Password.ToPlainText()) } else { "" }

            # Nexus Values
            "{{ nexus_fqdn .*?}}"                                    = if ($Data.NexusUri) { ([uri]$Data.NexusUri).DnsSafeHost } else { "" }
            "{{ nexus_port .*?}}"                                    = if ($Data.NexusUri) { ([uri]$Data.NexusUri).Port } else { "" }
            "{{ nexus_password .*?}}"                                = if ($Data.NexusCredential) { [System.Web.HttpUtility]::HtmlEncode($Data.NexusCredential.Password.ToPlainText()) } else { "" }
            "{{ lookup\('file', 'credentials\/nexus_apikey'\) .*?}}" = if ($Data.NugetApiKey) { $Data.NugetApiKey.ToPlainText() } else { "" }

            "{{ nexus_client_username .*?}}"                         = 'chocouser'
            "{{ nexus_client_password .*?}}"                         = if ($Data.ChocoUserPassword) { [System.Web.HttpUtility]::HtmlEncode($Data.ChocoUserPassword.ToPlainText()) } else { "" }

            "{{ nexus_packager_username .*?}}"                       = if ($Data.PackageUploadCredential) { $Data.PackageUploadCredential.Username } else { "" }
            "{{ nexus_packager_password .*?}}"                       = if ($Data.PackageUploadCredential) { [System.Web.HttpUtility]::HtmlEncode($Data.PackageUploadCredential.Password.ToPlainText()) } else { "" }

            # PowerShell Universal Values
            "{{ psu_fqdn .*?}}"                                      = if ($Data.PowerShellUniversalUri) { ([uri]$Data.PowerShellUniversalUri).DnsSafeHost } else { "" }
            "{{ psu_port .*?}}"                                      = if ($Data.PowerShellUniversalUri) { ([uri]$Data.PowerShellUniversalUri).Port } else { "" }
            "{{ psu_password .*?}}"                                  = if ($Data.PSUCredential) { [System.Web.HttpUtility]::HtmlEncode($Data.PSUCredential.Password.ToPlainText()) } else { "" }

            # Jenkins Values
            "{{ jenkins_fqdn .*?}}"                                  = if ($Data.JenkinsUri) { ([uri]$Data.JenkinsUri).DnsSafeHost } else { "" }
            "{{ jenkins_port .*?}}"                                  = if ($Data.JenkinsUri) { ([uri]$Data.JenkinsUri).Port } else { "" }
            "{{ jenkins_password .*?}}"                              = if ($Data.JenkinsCredential) { [System.Web.HttpUtility]::HtmlEncode($Data.JenkinsCredential.Password.ToPlainText()) } else { "" }
        }
    }
}