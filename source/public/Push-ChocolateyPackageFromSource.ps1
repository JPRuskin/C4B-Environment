function Push-ChocolateyPackageFromSource {
    <#
        .Synopsis
            Downloads (and optionally internalizes) a given package from a given source, then pushes it to a given URL

        .Example
            Push-ChocolateyPackageFromSource -Name chocolateygui -TargetFeed http://localhost:8081/repository/Test -ApiKey $ApiKey
    #>
    param(
        # The name of the package to download
        [string[]]$Name,

        # If passed, internalizes the package before pushing it
        [switch]$Internalize,

        # The URL of the feed to push the package to
        [string]$TargetFeed,

        # The source to download packages from. Defaults to the Chocolatey Community Repository.
        [string]$Source = "https://community.chocolatey.org/api/v2",

        # The Api Key with access to the target feed
        [string]$ApiKey
    )
    begin {
        $WorkingDirectory = Join-Path $env:Temp "$(New-Guid)"
        if (-not (Test-Path $WorkingDirectory)) {
            New-Item $WorkingDirectory -ItemType Directory -Force
        }
    }
    process {
        foreach ($Package in $Name) {
            if ($Internalize) {
                choco download $Package --source $Source --outputdirectory $WorkingDirectory --internalize
            } else {
                choco download $Package --source $Source --outputdirectory $WorkingDirectory
            }
        }
    }
    end {
        foreach ($Package in (Get-ChildItem -Path $WorkingDirectory -Filter *.nupkg -ErrorAction 'SilentlyContinue')) {
            choco push $Package.FullName --source="$TargetFeed" --api-key="$ApiKey"
        }

        Remove-Item $WorkingDirectory -Force -Recurse
    }
}