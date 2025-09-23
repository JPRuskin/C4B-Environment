function Invoke-NexusScript {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]
        [String]
        $ServerUri,

        [Parameter(Mandatory)]
        [Hashtable]
        $ApiHeader,
    
        [Parameter(Mandatory)]
        [String]
        $Script
    )
    try {
        $scriptName = [GUID]::NewGuid().ToString()
        New-NexusScript -Name $scriptName -Content $Script -Type "groovy"
        Start-NexusScript -Name $scriptName
    } finally {
        Remove-NexusScript -Name $scriptName
    }
}