function Set-ChocoEnvironmentProperty {
    [CmdletBinding(DefaultParameterSetName="Key")]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName="Key", Position=0)]
        [Alias('Key')]
        [string]$Name,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName="Key", Position=1)]
        $Value,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName="Hashtable")]
        [hashtable]$InputObject = @{}
    )
    begin {
        $Properties = $InputObject
    }
    process {
        $Properties.$Name = $Value
    }
    end {
        Update-Clixml -Path "$env:SystemDrive\choco-setup\clixml\chocolatey-for-business.xml" -Properties $Properties
    }
}