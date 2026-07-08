function Set-AppSettingsDefaultConnectionString {
    <#
        .Synopsis
            Sets the default connection string to the given value
    #>
    [CmdletBinding()]
    param(
        # The path to the appsettings.json file to update
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Path,

        # The connection string to add or update
        [Parameter(Mandatory)]
        [string]$ConnectionString
    )
    begin {
        # Validate ConnectionString with Test-CcmConnectionString?
    }
    process {
        if (Test-Path $Path -PathType Container) {
            $Path = Join-Path $Path 'appsettings.json'
        }
        $JsonContent = Get-Content $Path | ConvertFrom-Json
        $JsonContent.ConnectionStrings.Default = $ConnectionString
        $JsonContent | ConvertTo-Json | Set-Content $Path
    }
}