function Invoke-JenkinsApi {
    <#
        .Synopsis
            Invokes an existing job on a Jenkins server
        .Example
            Invoke-JenkinsApi
    #>
    param(
        # The name of the job to invoke
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Slug,

        # The URI of the Jenkins server, including protocols and port if required
        [ValidateNotNullOrEmpty()]
        [string]$Uri = 'http://localhost:8080/jenkins',

        [string]$Method = "GET",

        # The Jenkins credential to authenticate with
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential,

        # Any body to pass
        [hashtable]$Body,

        # If provided, fetches a Jenkins Crumb from the server before kicking off the request
        [switch]$RequiresCrumb
    )
    $RequestParams = @{}

    $Header = @{}
    $Header['Authorization'] = 'Basic {0}' -f ([Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($Credential.UserName):$($Credential.GetNetworkCredential().Password)")))
    $RequestParams['Headers'] = $Header

    if ($RequiresCrumb) {
        $JenkinsWebSession = New-Object Microsoft.PowerShell.Commands.WebRequestSession

        $RequestParams['Uri'] = '{0}/crumbIssuer/api/json' -f $Uri
        $RequestParams['Method'] = 'GET'

        $RequestParams['WebSession'] = $JenkinsWebSession

        $CrumbResponse = Invoke-RestMethod @RequestParams

        $Header['Jenkins-Crumb'] = $CrumbResponse.crumb
        $RequestParams['Uri'] = '{0}/me/descriptorByName/jenkins.security.ApiTokenProperty/generateNewToken?newTokenName=GHA' -f $Uri
        $RequestParams['Method'] = 'POST'
        $RequestParams['Headers'] = $Header

        $Token = (Invoke-RestMethod @RequestParams).data.tokenValue
        $RequestParams.Headers['Authorization'] = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($Credential.UserName):$($Token)"))
    }

    $RequestParams['Uri'] = '{0}/{1}' -f $Uri.TrimEnd('/'), $Slug.TrimStart('/')
    $RequestParams['Method'] = $Method

    if ($Body) {
        $RequestParams['Body'] = $Body
    }

    Invoke-RestMethod @RequestParams
}