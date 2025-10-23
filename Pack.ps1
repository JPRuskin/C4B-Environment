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

# Compress-Archive -Path "$PSScriptRoot\$SemVer\" -DestinationPath "$PSScriptRoot\C4B-Environment.$SemVer.zip"

choco pack $PSScriptRoot\chocolatey\c4b-environment.nuspec --Version $SemVer --OutputDirectory $PSScriptRoot --limit-output | Write-Verbose

Get-Item "$PSScriptRoot\c4b-environment.powershell.$SemVer.nupkg"