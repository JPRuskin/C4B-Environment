function Update-Clixml {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Path = "$env:SystemDrive\choco-setup\clixml\chocolatey-for-business.xml",

        [Parameter(Mandatory)]
        [hashtable]$Properties
    )
    $CliXml = if (Test-Path $Path) {
        Import-Clixml $Path
    } else {
        if (-not (Test-Path (Split-Path $Path -Parent))) {
            $null = mkdir (Split-Path $Path -Parent) -Force
        }
        [PSCustomObject]@{}
    }

    $Properties.GetEnumerator().ForEach{
        Add-Member -InputObject $CliXml -MemberType NoteProperty -Name $_.Key -Value $_.Value -Force
    }

    $CliXml | Export-Clixml $Path -Force
}