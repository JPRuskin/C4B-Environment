function Get-ChocolateyPackageMetadata {
    [CmdletBinding(DefaultParameterSetName='All')]
    param(
        # The folder or nupkg to check
        [Parameter(Mandatory, Position=0, ValueFromPipelineByPropertyName)]
        [string]$Path,

        # If provided, filters found packages by ID
        [Parameter(Mandatory, Position=1, ParameterSetName='Id')]
        [SupportsWildcards()]
        [Alias('Name')]
        [string]$Id = '*'
    )
    process {
        Get-ChildItem $Path -Filter $Id*.nupkg | ForEach-Object {
            ([xml](Find-FileInArchive -Path $_.FullName -Like *.nuspec | Get-FileContentInArchive)).package.metadata | Where-Object Id -like $Id
        }
    }
}