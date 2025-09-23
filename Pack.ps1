[CmdletBinding()]
param(
    $SemVer = $(
        if (Get-Command gitversion -EA 0) {
            gitversion /showvariable SemVer
        } else {
            "0.0.1"
        }
    )
)

choco pack $PSScriptRoot\chocolatey\c4b-environment.nuspec --Version $SemVer --OutputDirectory $PSScriptRoot