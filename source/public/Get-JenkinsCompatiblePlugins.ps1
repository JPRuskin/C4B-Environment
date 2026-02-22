function Get-JenkinsCompatiblePlugins {
    <#
        .SYNOPSIS
            Retrieves the latest compatible Jenkins plugin versions for a specified Jenkins core version.

        .OUTPUTS
            PSCustomObject containing plugin name, version, URL, and dependencies.

        .EXAMPLE
            Get-JenkinsCompatiblePlugins -CoreVersion 2.528.2 -PluginNames "workflow-api","git","matrix-auth"
    #>
    param(
        # The Jenkins core version to look up. If not provided, defaults to the latest.
        [Parameter()]
        [string]
        $CoreVersion = $(
            if (Test-Path $env:ProgramData\Jenkins\.jenkins\.lastStarted) {
                Get-Content $env:ProgramData\Jenkins\.jenkins\.lastStarted
            } elseif ((Get-Command choco.exe -ErrorAction SilentlyContinue) -and ($Package = choco list jenkins -r)) {
                $Package | ConvertFrom-Csv -Delimiter '|' -Header Name, Version | Select-Object -ExpandProperty Version
            }
        ),

        # An array of plugin short names to look up.
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]
        $PluginNames,

        # If passed, outputs all dependencies as well as the listed plugins
        [switch]$Recurse
    )
    begin {
        if (-not ($Script:CachedJenkinsPlugins)) {
            $Script:CachedJenkinsPlugins = @{}
        }

        if (-not ($Script:CachedJenkinsPlugins[$CoreVersion])) {
            # Jenkins version-aware update site JSON URL
            $UpdateUrl = "https://updates.jenkins.io/update-center.actual.json$(if ($CoreVersion) {"?version=$CoreVersion"})"

            Write-Verbose "Downloading update center JSON for Jenkins $CoreVersion ..."
            $RestResponse = Invoke-RestMethod -Uri $UpdateUrl -ErrorAction Stop

            # Update-center.actual.json returns a wrapper with an inner "plugins" dictionary
            if (-not $RestResponse.plugins) {
                throw "Update site JSON did not contain plugin data. Verify the Jenkins version."
            }
            $Script:CachedJenkinsPlugins[$CoreVersion] = $RestResponse.plugins
        }

        $Results = [System.Collections.Generic.List[PSCustomObject]]::new()
    }
    process {
        $Results += foreach ($Name in $PluginNames) {
            Write-Verbose "Looking for '$($Name)'"
            $plugin = $Script:CachedJenkinsPlugins[$CoreVersion].$Name

            if (-not $plugin) {
                Write-Warning "$($Name) was not found in the response from '$($UpdateUrl)'"
                continue
            }

            [PSCustomObject]@{
                Name         = $plugin.name
                Title        = $plugin.title
                Version      = $plugin.version
                URL          = $plugin.url
                Dependencies = $plugin.dependencies
            }
        }

        if ($Recurse) {
            foreach ($Plugin in $Results.Dependencies | Where-Object optional -NE 'True') {
                if ($Plugin.name -and $Results.Name -notcontains $Plugin.name) {
                    Get-JenkinsCompatiblePlugins -CoreVersion $CoreVersion -PluginNames $Plugin.name -Recurse | ForEach-Object {
                        if ($Results -notcontains $_) { $Results += $_ }
                    }
                }
            }
        }
    }
    end {
        $Results | Sort-Object Name -Unique
    }
}
