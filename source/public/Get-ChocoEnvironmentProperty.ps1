function Get-ChocoEnvironmentProperty {
    <#
        .SYNOPSIS
            Returns the value of a stored environment property

        .DESCRIPTION
            Returns the value of a stored environment property, from the module storage location

        .EXAMPLE
            Get-ChocoEnvironmentProperty

            # Returns all stored properties

        .EXAMPLE
            Get-ChocoEnvironmentProperty NexusUri

            # Returns a string property

        .EXAMPLE
            Get-ChocoEnvironmentProperty ChocoUserPassword -AsPlainText

            # Returns a securestring property as plain text

        .EXAMPLE
            (Get-ChocoEnvironmentProperty ChocoUserCredential).Password.ToPlainText()

            # Returns the password for a credential object
    #>
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