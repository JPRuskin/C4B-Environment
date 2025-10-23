function Get-ChocolateyBusinessManifestPackageVersion {
    [CmdletBinding()]
    [Alias('pv')]
    param(
        # The id of the package to get a version for.
        [Parameter(Mandatory)]
        $Id,

        # The specific server type to check.
        $ServerType = "*"
    )
    Get-ChocolateyBusinessManifest -ServerType $ServerType | % chocolatey | Where-Object name -EQ $Id | Select-Object -ExpandProperty version -First 1
}