function Save-JenkinsPlugin {
    <#
        .SYNOPSIS
            Saves Jenkins plugins, given a name and version, or URL.

        .DESCRIPTION
            Given a URL and output path, or a name and version to combine, saves Jenkins plugins to a given directory.

        .EXAMPLE
            Get-JenkinsCompatiblePlugins -CoreVersion 2.528.2 -PluginNames "workflow-api","git","matrix-auth" | Save-JenkinsPlugin

        .EXAMPLE
            Save-JenkinsPlugin -Name "workflow-api" -Version _2b.401.k
    #>
    [CmdletBinding(DefaultParameterSetName = "Combined")]
    param(
        [Parameter(Mandatory, ParameterSetName = "Split", ValueFromPipelineByPropertyName)]
        [string]
        $Name,

        [Parameter(Mandatory, ParameterSetName = "Split", ValueFromPipelineByPropertyName)]
        [string]
        $Version,

        [Parameter(Mandatory, ParameterSetName = "Combined", ValueFromPipelineByPropertyName)]
        [string]
        $Url = "https://updates.jenkins.io/download/plugins/$($Name)/$($Version)/$($Name).hpi",

        [Parameter()]
        [string]
        $OutputPath = $pwd.Path
    )
    begin {
        if (-not (Test-Path $OutputPath)) {
            $null = New-Item -Path $OutputPath -ItemType Directory -Force
        }
    }
    process {
        $FilePath = Join-Path $OutputPath "$(Split-Path $Url -Leaf)"

        if (-not (Test-Path $FilePath) -or ($ForceDownload = (Get-JenkinsPluginMetadata -Path $FilePath)."Plugin-Version" -ne $Version)) {
            Write-Verbose "Downloading $Url to $FilePath"
            Invoke-WebRequest -Uri $Url -OutFile $FilePath -ErrorAction Stop -Force:$ForceDownload
        }

        Get-Item $FilePath
    }
}
