class PackageDependency {
    [Alias('Name')]
    [string]$Id
    $Version
    [PackageDependency[]]$Dependencies

    PackageDependency () {}

    PackageDependency ($Id) {
        $NuspecPath = "$env:ChocolateyInstall\lib\$Id\$Id.nuspec"

        if (Test-Path $NuspecPath) {
            [xml]$Nuspec = Get-Content $NuspecPath
            $Namespace = [Xml.XmlNamespaceManager]::new($Nuspec.NameTable)
            $Namespace.AddNamespace("nuspec", $Nuspec.package.xmlns)

            $this.Id = $Nuspec.package.metadata.id
            $this.Version = $Nuspec.package.metadata.version
            $this.Dependencies = $Nuspec.SelectNodes("//nuspec:dependency", $Namespace).id
        } else {
            $QueryString = "Id eq '$Id' and IsLatestVersion"
            $QueryUrl = 'https://community.chocolatey.org/api/v2/Packages()?$filter={0}' -f [uri]::EscapeUriString($queryString)
            [xml]$Nuspec = Invoke-WebRequest $QueryUrl -UseBasicParsing  # Not actually a nuspec

            $this.Id = $Nuspec.feed.entry.title.'#text'
            $this.Version = $Nuspec.feed.entry.Version
            $this.Dependencies = $Nuspec.feed.entry.properties.Dependencies.ForEach{ [PackageDependency]::new($_.Split(":")[0], $_.Split(":")[1]) } # $_.Split(":") }
        }
    }

    PackageDependency ($Id, $Version) {
        $NuspecPath = "$env:ChocolateyInstall\lib\$Id\$Id.nuspec"

        if (Test-Path $NuspecPath) {
            [xml]$Nuspec = Get-Content $NuspecPath
            $Namespace = [Xml.XmlNamespaceManager]::new($Nuspec.NameTable)
            $Namespace.AddNamespace("nuspec", $Nuspec.package.xmlns)

            $this.Id = $Nuspec.package.metadata.id
            $this.Dependencies = $Nuspec.SelectNodes("//nuspec:dependency", $Namespace).id
        } else {
            $QueryUrl = "https://community.chocolatey.org/api/v2/Packages(Id='$Id',Version='$Version')"
            try {
                [xml]$Nuspec = Invoke-WebRequest $QueryUrl -UseBasicParsing  # Not actually a nuspec

                $this.Id = $Nuspec.feed.entry.title.'#text'
                $this.Version = $Nuspec.feed.entry.Version
                $this.Dependencies = $Nuspec.feed.entry.properties.Dependencies.ForEach{ [PackageDependency]::new($_.Split(":")[0], $_.Split(":")[1]) }
            } catch {
                if ($_.Message -match "Resource not found for the segment 'Packages'.") {
                    Write-Error "Package '$Id' with version '$Version' was not found with '$QueryUrl':`n$_"
                } else {
                    throw
                }
            }
        }
    }

    static [PackageDependency[]] GetDependencies ($Id, $VersionRange) {
        return @()  # TODO: Implement this method, replace the code in the constructors
        # Note: Ensure it only runs if there's not already dependencies, so we can call it at the start of out / tree without perf issues
    }

    # static [bool] VersionSatisfies ($VersionRange, $Version) {
    #     # This assumes you have Chocolatey and Chocolatey.Extension installed and licensed correctly.
    #     if (-not ('Nuget.Versioning.VersionRange' -as [type])) {
    #         try {
    #             Add-Type -AssemblyName $env:ChocolateyInstall\choco.exe
    #         } catch {
    #             $null = [System.Reflection.Assembly]::Loadfrom("$env:ChocolateyInstall\choco.exe")
    #         }
    #     }

    #     return ([NuGet.Versioning.VersionRange]$VersionRange).Satisfies($Version)
    # }

    [string[]] OutDependencies() {
        [string[]]$Packages = foreach ($Dependency in $this.Dependencies) {
            $Dependency.OutDependencies()
        }

        return $Packages + $this.Id | Select-Object -Unique
    }
}