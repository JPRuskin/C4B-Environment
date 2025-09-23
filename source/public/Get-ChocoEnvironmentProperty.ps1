function Get-ChocoEnvironmentProperty {
    [CmdletBinding(DefaultParameterSetName="All")]
    param(
        [Parameter(ParameterSetName="Specific", Mandatory, ValueFromPipeline, Position=0)]
        [string]$Name,

        [Parameter(ParameterSetName="Specific")]
        [switch]$AsPlainText
    )
    begin {
        if (Test-Path "$env:SystemDrive\choco-setup\clixml\chocolatey-for-business.xml") {
            $Content = Import-Clixml -Path "$env:SystemDrive\choco-setup\clixml\chocolatey-for-business.xml"
        }
    }
    process {
        if ($Name) {
            if ($AsPlainText -and $Content.$Name -is [System.Security.SecureString]) {
                return $Content.$Name.ToPlainText()
            } else {
                return $Content.$Name
            }
        } else {
            $Content
        }
    }
}