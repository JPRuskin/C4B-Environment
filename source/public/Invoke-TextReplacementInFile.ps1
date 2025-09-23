function Invoke-TextReplacementInFile {
    [CmdletBinding()]
    param(
        # The path to the file(s) to replace text in.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        [string]$Path,

        # The replacements to make, in a key-value format.
        [hashtable]$Replacement
    )
    process {
        $Content = Get-Content -Path $Path -Raw
        $Replacement.GetEnumerator().ForEach{
            $Content = $Content -replace $_.Key, $_.Value
        }
        $Content | Set-Content -Path $Path -NoNewline
    }
}