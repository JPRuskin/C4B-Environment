function Get-FileContentInArchive {
    <#
        .Synopsis
            Returns the content of a file from within an archive
        .Example
            Get-FileContentInArchive -Path $ZipPath -Name "chocolateyInstall.ps1"
        .Example
            Get-FileContentInArchive -Zip $Zip -FullName "tools\chocolateyInstall.ps1"
        .Example
            Find-FileInArchive -Path $ZipPath -Like *.nuspec | Get-FileContentInArchive
    #>
    [CmdletBinding(DefaultParameterSetName = "PathFullName")]
    [OutputType([string])]
    param(
        # Path to the archive
        [Parameter(Mandatory, ParameterSetName = "PathFullName")]
        [Parameter(Mandatory, ParameterSetName = "PathName")]
        [string]$Path,

        # Zip object for the archive
        [Parameter(Mandatory, ParameterSetName = "ZipFullName", ValueFromPipelineByPropertyName)]
        [Parameter(Mandatory, ParameterSetName = "ZipName", ValueFromPipelineByPropertyName)]
        [Alias("Archive")]
        [IO.Compression.ZipArchive]$Zip,

        # Name of the file(s) to remove from the archive
        [Parameter(Mandatory, ParameterSetName = "PathFullName", ValueFromPipelineByPropertyName)]
        [Parameter(Mandatory, ParameterSetName = "ZipFullName", ValueFromPipelineByPropertyName)]
        [string]$FullName,

        # Name of the file(s) to remove from the archive
        [Parameter(Mandatory, ParameterSetName = "PathName")]
        [Parameter(Mandatory, ParameterSetName = "ZipName")]
        [string]$Name
    )
    begin {
        if (-not $PSCmdlet.ParameterSetName.StartsWith("Zip")) {
            $Stream = [IO.FileStream]::new($Path, [IO.FileMode]::Open)
            $Zip = [IO.Compression.ZipArchive]::new($Stream, [IO.Compression.ZipArchiveMode]::Read)
        }
    }
    process {
        if (-not $FullName) {
            $MatchingEntries = $Zip.Entries | Where-Object {$_.Name -eq $Name}
            if ($MatchingEntries.Count -ne 1) {
                Write-Error "File '$Name' not found in archive" -ErrorAction Stop
            }
            $FullName = $MatchingEntries[0].FullName
        }
        [System.IO.StreamReader]::new(
            $Zip.GetEntry($FullName).Open()
        ).ReadToEnd()
    }
    end {
        if (-not $PSCmdlet.ParameterSetName.StartsWith("Zip")) {
            $Zip.Dispose()
            $Stream.Close()
            $Stream.Dispose()
        }
    }
}