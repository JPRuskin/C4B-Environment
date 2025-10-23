function Get-ChocolateyBusinessManifest {
    <#
        .SYNOPSIS
            Gets the expected packages for a given server in a Chocolatey for Business environment.

        .DESCRIPTION
            Refers to the Chocolatey manifest and returns a deduplicated list of packages to install
            on any given server in a Chocolatey for Business environment, along with optional plugins
            etc.

        .EXAMPLE
            $Manifest = Get-ChocolateyBusinessManifest -ServerType jenkins
            $Manifest.chocolatey         # returns all Chocolatey packages
            $Manifest.jenkinsplugins     # returns all Jenkins plugins

        .EXAMPLE
            Get-ChocolateyBusinessManifest -ServerType *  # All servers

        .EXAMPLE
            Get-ChocolateyBusinessManifest -ServerType chocolatey-management-*,nexus
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [ArgumentCompleter({
                (Get-Content $PSScriptRoot\data\chocolatey.json | ConvertFrom-Json).PSObject.Properties.Name
            })]
        [string[]]$ServerType = "*"
    )
    begin {
        $Manifest = Get-Content $PSScriptRoot\data\chocolatey.json | ConvertFrom-Json
        $Result = @{}
    }
    process {
        foreach ($Type in $ServerType) {
            Write-Verbose "Checking $Type"
            $Manifest.PSObject.Properties.Name.Where{
                $_ -like $Type
            }.ForEach{
                $MatchingServerType = $_
                Write-Verbose "Adding $MatchingServerType to Result"
                foreach ($Property in $Manifest.$MatchingServerType.PSObject.Properties.Name) {
                    Write-Verbose "Looking at $Property (1)"
                    if (-not $Result.$Property) { $Result.$Property = @() }
                    foreach ($SubProperty in $Manifest.$MatchingServerType.$Property) {
                        Write-Verbose "Looking at $($SubProperty) (2)"
                        if ($Result.$Property.Name -notcontains $SubProperty.Name) {
                            $Result.$Property += [PSCustomObject]$SubProperty
                        }
                    }
                }
            }
        }
    }
    end {
        [PSCustomObject]$Result
    }
}