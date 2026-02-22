filter Get-JenkinsPluginMetadata {
    [CmdletBinding()]
    param(
        # The path to the Jenkins plugin file
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Path
    )

    $(Find-FileInArchive -Path $Path -Match "^META-INF/MANIFEST.MF$" | Get-FileContentInArchive) -replace "\r?\n\s+" | Select-String -Pattern "(?m)^(?<Key>.+): (?<Value>.+)\n(?=^.+: )" -AllMatches | Select-Object -ExpandProperty Matches | ForEach-Object {
        "$($_.Groups[1].Value)=$($_.Groups[2].Value)"
    } | ConvertFrom-StringData
}