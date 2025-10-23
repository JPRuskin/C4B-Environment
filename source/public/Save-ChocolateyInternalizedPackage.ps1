# function Save-ChocolateyInternalizedPackage {
#     [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = "Piped")]
#     param(
#         [Parameter(ValueFromPipeline, ParameterSetName = "Piped")]
#         [Alias("chocolatey")]
#         [PackageDownload[]]$InputObject,

#         [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = "Individual")]
#         [Alias('Name')]
#         [string]$Id,

#         [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = "Individual")]
#         [string]$Version,

#         [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = "Individual")]
#         [switch]$Internalize,

#         [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = "Individual")]
#         [Parameter(ParameterSetName = "Piped")]
#         [string]$Source,

#         [Alias('OutputDirectory')]
#         [string]$OutputPath = $PWD.Path
#     )
#     begin {
#         $WorkingDirectory = Join-Path $env:TEMP "choco-offline"
#         $PackageWorkingDirectory = Join-Path $WorkingDirectory "packages"

#         if (-not (Test-Path $PackageWorkingDirectory)) {
#             $null = New-Item -Path $PackageWorkingDirectory -ItemType Directory -Force
#         }

#         if (-not (Test-Path $OutputPath)) {
#             $null = New-Item -Path $OutputPath -ItemType Directory -Force
#         }

#         if ($PSCmdlet.ParameterSetName -eq "Individual") {
#             $InputObject = [PackageDownload]$PSBoundParameters
#             # @{
#             #     Id          = $Id
#             #     Version     = $Version
#             #     Internalize = $Internalize
#             #     Source      = $Source
#             # }
#         }
#     }
#     process {
#         foreach ($Package in $InputObject) {
#             Write-Verbose "Downloading '$($Package | ConvertTo-Json)'"

#             try {
#                 if (-not (Get-ChocolateyPackageMetadata -Path $PackageWorkingDirectory -Id $Package.Id)) {
#                     Write-Host "Downloading '$($Package.Id)'"

#                     while ((Get-ChildItem $PackageWorkingDirectory -Filter *.nupkg).Where{$_.CreationTime -gt (Get-Date).AddMinutes(-1)}.Count -gt 5) {
#                         Write-Verbose "Slowing down for a minute, in order to not trigger rate-limiting..."
#                         Start-Sleep -Seconds 5
#                     }

#                     if ($PSCmdlet.ShouldProcess($Package.Id, "Downloading")) {
#                         Invoke-Choco @(
#                             "download"
#                             $Package.Id
#                             if ($Package.Version) {
#                                 "--version=$($Package.Version)"
#                             }
#                             "--output-directory"
#                             $PackageWorkingDirectory
#                             "--ignore-dependencies"  # TODO: Replace this with the dependency injection calculation?
#                             "--no-progress"
#                             if ($Package.Internalize) {
#                                 "--internalize"
#                             }
#                             if ($Package.Source) {
#                                 "--source='$($Package.Source)'"
#                             }
#                         )
#                     }
#                 }
#             } catch {
#                 throw $_
#             }
#         }
#     }
#     end {
#         Copy-Item -Path $PackageWorkingDirectory/*.nupkg -Destination $OutputPath -PassThru
#     }
# }
#

# This assumes you have Chocolatey and Chocolatey.Extension installed and licensed correctly.
if (-not ('Nuget.Versioning.VersionRange' -as [type])) {
    try {
        Add-Type -AssemblyName $env:ChocolateyInstall\choco.exe
    } catch {
        $null = [System.Reflection.Assembly]::Loadfrom("$env:ChocolateyInstall\choco.exe")
    }
}

function Save-ChocolateyInternalizedPackage {
    [Alias('Get-InternalizedPackage')]
    <#
        .Synopsis
            Downloads and internalizes Chocolatey packages.
        .Example
            Get-InternalizedPackage cloudflared
            # Returns a 'cloudflared' package with all binaries internalized.
        .Example
            Get-InternalizedPackage cloudflared -Source ChocolateyInternal
            # Returns a 'cloudflare' package with all binaries internalized, from a specific source.
        .Example
            "dotnet-6.0-runtime", "dotnet-6.0-aspnetruntime", "dotnet-aspnetcoremodule-v2" | Get-InternalizedPackage -RemoveDependency KB2919355, KB219442, KB3033929, KB2999226 | Sort -Unique
            # Returns all of the listed packages, and their dependencies, having removed some listed dependencies from the chain.
        .Notes
            This function is written far more trustingly than Chocolatey - e.g. it will not halt if it finds existing files.
    #>
    [OutputType([System.IO.FileInfo])]
    [CmdletBinding()]
    param(
        # The package to download.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Name')]
        [string]$Id,

        # The version to download.
        [Parameter(ValueFromPipelineByPropertyName)]
        [Nuget.Versioning.VersionRange]$Version,

        # The source to download the package from.
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Source,

        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]$SkipInternalize,

        # If added, removes the listed dependencies from the package before repacking it.
        # WARNING: This can obviously create packages that don't work. Be careful.
        [string[]]$RemoveDependency
    )
    begin {
        $WorkingDirectory = Join-Path $env:TEMP "chocointernalize"
        if (-not (Test-Path $WorkingDirectory)) {$null = mkdir $WorkingDirectory}

        $SharedParameters = @{}
        $PSBoundParameters.GetEnumerator().ForEach{
            if ($_.Key -in @("RemoveDependency", "Source")) {
                $SharedParameters += @{$_.Key = $_.Value}
            }
        }
    }
    process {
        $PackageChanged = $false

        # Download or find the package files
        if (Test-Path "$WorkingDirectory\download\$Id") {
            Write-Verbose "Using previously downloaded files in '$WorkingDirectory\download\$Id'"
        } else {
            Write-Verbose "Downloading package '$($Id)'"
            $DownloadResult = choco @(
                "download", $Id
                if ($Version) {
                    $FoundVersion = if ($Version.OriginalString -as [NuGet.Versioning.SemanticVersion]) {
                        $Version.OriginalString
                    } else {
                        Write-Verbose "Finding Available Versions of '$($Id)'"
                        choco @(
                            "find"
                            $Id
                            "--exact"
                            "--all-versions"
                            if ($Source) {"--source=$Source"}
                            "--limit-output"
                        ) | ConvertFrom-Csv -Delimiter '|' -Header Id, Version | Where-Object {
                            $Version.Satisfies($_.Version)
                            #} | Sort-Object -Descending {
                            ## It may be necessary to sort, if we can't rely on the order returned
                            #    [NuGet.Versioning.SemanticVersion]$_.Version
                        } | Select-Object -First 1 -ExpandProperty Version
                    }
                    Write-Verbose "Using Version '$($FoundVersion)'"
                    "--version=$FoundVersion"
                }
                if ($Source) {"--source=$Source"}
                "--internalize"
                "--internalize-all-urls"
                "--ignore-dependencies"
                "--output-directory=$($WorkingDirectory)"
                "--no-progress"
            )
            if ($LastExitCode -ne 0) {
                $DownloadResult
                throw
            }
        }

        # Get the metadata for the downloaded package
        $NuspecPath = "$WorkingDirectory\download\$Id\$Id.nuspec"
        [xml]$Nuspec = Get-Content $NuspecPath
        $Namespace = [Xml.XmlNamespaceManager]::new($Nuspec.NameTable)
        $Namespace.AddNamespace("nuspec", $Nuspec.package.xmlns)

        # Check for dependencies we want to exclude
        foreach ($UnwantedDependency in $RemoveDependency) {
            if ($FoundDependency = $Nuspec.SelectSingleNode("//nuspec:dependency[@id='$($UnwantedDependency)']", $Namespace)) {
                $PackageChanged = $true

                Write-Verbose "Removing dependency '$($UnwantedDependency)' from '$($Id)'"
                $null = $Nuspec.SelectSingleNode("//nuspec:dependencies", $Namespace).RemoveChild($FoundDependency)
            }
        }

        # Save any modifications made
        if ($PackageChanged) {
            $Nuspec.Save($NuspecPath)

            Write-Verbose "Repacking '$($Id)'"
            $PackingResult = choco @(
                "pack"
                $NuspecPath
                "--output-directory=$WorkingDirectory"
                "--limit-output"
            )
            if ($LastExitCode -ne 0) {
                $PackingResult
                throw
            }
        } else {
            Write-Verbose "There were no changes made to '$($Id)'"
        }

        # Return the package
        Get-Item "$WorkingDirectory\$Id.$($Nuspec.package.metadata.version).nupkg"

        # Recursively download any remaining dependencies
        foreach ($Dependency in $Nuspec.SelectNodes("//nuspec:dependency", $Namespace)) {
            Get-InternalizedPackage -Id $Dependency.Id -Version $Dependency.Version @SharedParameters
        }
    }
}