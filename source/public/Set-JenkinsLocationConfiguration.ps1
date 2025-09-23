function Set-JenkinsLocationConfiguration {
    <#
        .Synopsis
            Sets the jenkinsUrl in the location configuration file.

        .Example
            Set-JenkinsURL -Url 'http://jenkins.fabrikam.com:8080'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        # The full URI to access Jenkins on, including port and scheme.
        [string]$Url,

        # The address to use as the admin e-mail address.
        [string]$AdminAddress = 'address not configured yet &lt;nobody@nowhere&gt;',

        [string]$Path = "C:\ProgramData\Jenkins\.jenkins\jenkins.model.JenkinsLocationConfiguration.xml"
    )
    @"
<?xml version='1.1' encoding='UTF-8'?>
<jenkins.model.JenkinsLocationConfiguration>
<adminAddress>$AdminAddress</adminAddress>
<jenkinsUrl>$Url</jenkinsUrl>
</jenkins.model.JenkinsLocationConfiguration>
"@ | Out-File -FilePath $Path -Encoding utf8
}