function Invoke-JenkinsJob {
    <#
        .Synopsis
            Invokes an existing job on a Jenkins server
        .Example
            Invoke-JenkinsJob -Name "Internalize packages from the Chocolatey Community and Licensed Repositories" -Uri http://localhost:8081/jenkins -Credential $JenkinsCredential -Parameters @{P_PKG_LIST="nexus-repository,jenkins"}
    #>
    param(
        # The name of the job to invoke
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        # The URI of the Jenkins server, including protocols and port if required
        [ValidateNotNullOrEmpty()]
        [string]$Uri = 'http://localhost:8080/jenkins',

        # The Jenkins credential to authenticate with
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential,

        # Any job parameters
        [hashtable]$Parameters
    )
    Invoke-JenkinsApi -Uri "$($Uri.TrimEnd('/'))/job/$Name/buildWithParameters" -Body $Parameters -Credential $Credential -RequiresCrumb
}