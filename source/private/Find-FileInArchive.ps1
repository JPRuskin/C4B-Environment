function Find-FileInArchive {
    <#
        .Synopsis
            Finds files with a name matching a pattern in an archive.
        .Example
            Find-FileInArchive -Path "C:\Archive.zip" -like "tools/files/*-x86.exe"
        .Example
            Find-FileInArchive -Path $Nupkg -match "tools/files/dotnetcore-sdk-(?<Version>\d+\.\d+\.\d+)-win-x86\.exe(\.ignore)?"
        .Notes
            Please be aware that this matches against the full name of the file, not just the file name.
            Though given that, you can easily write something to match the file name.
    #>
    [CmdletBinding(DefaultParameterSetName = "match")]
    param(
        # Path to the archive
        [Parameter(Mandatory)]
        [string]$Path,

        # Pattern to match with regex
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = "match")]
        [string]$match,

        # Pattern to match with basic globbing
        [Parameter(Mandatory, ParameterSetName = "like")]
        [string]$like
    )
    begin {
        while (-not $Zip -and $AccessRetries++ -lt 3) {
            try {
                $Stream = [IO.FileStream]::new($Path, [IO.FileMode]::Open)
                $Zip = [IO.Compression.ZipArchive]::new($Stream, [IO.Compression.ZipArchiveMode]::Read)
            } catch [System.IO.IOException] {
                if ($AccessRetries -ge 3) {
                    Write-Error -Message "Accessing '$Path' failed after $AccessRetries attempts." -TargetObject $Path
                } else {
                    Write-Information "Could not access '$Path', retrying..."
                    Start-Sleep -Milliseconds 500
                }
            }
        }
    }
    process {
        if ($Zip) {
            # Improve "security"?
            $WhereBlock = [ScriptBlock]::Create("`$_.FullName -$($PSCmdlet.ParameterSetName) '$(Get-Variable -Name $PSCmdlet.ParameterSetName -ValueOnly)'")
            $Zip.Entries | Where-Object -FilterScript $WhereBlock
        }
    }
    end {
        if ($Zip) {
            $Zip.Dispose()
        }
        if ($Stream) {
            $Stream.Close()
            $Stream.Dispose()
        }
    }
}