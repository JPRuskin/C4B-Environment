function Initialize-DataDisk {
    <#
        .Synopsis
            Finds attached datadisk, initializes and mounts it if missing.
    #>
    [CmdletBinding()]
    param(
        # Name of the initialized disk
        [string]$Name = "DataDisk",

        # Drive letter to mount the disk to
        [char]$DriveLetter = "R"
    )
    end {
        if (-not (Test-Path "$($DriveLetter):\")) {
            if (-not ($Volume = Get-Volume -FriendlyName $Name -ErrorAction SilentlyContinue)) {
                $PotentialDisk = Get-Disk | Where-Object PartitionStyle -EQ 'RAW'
                if (@($PotentialDisk).Count -ne 1) {
                    Write-Error "'$($PotentialDisk.Count)' uninitialized disks were found. Not proceeding." -ErrorAction Stop
                }

                Set-PhysicalDisk -UniqueId $PotentialDisk.UniqueId -NewFriendlyName $Name

                $Volume = Initialize-Disk -UniqueId $PotentialDisk.UniqueId -PartitionStyle MBR -Confirm:$false -PassThru |
                    New-Partition -DriveLetter $DriveLetter -UseMaximumSize |
                    Format-Volume -FileSystem NTFS -NewFileSystemLabel $Name -Confirm:$false
            }

            # Mount the partition if it's not mounted on the correct driveletter
            if ($Volume.DriveLetter -ne $DriveLetter) {
                $Disk = Get-PhysicalDisk -FriendlyName $Name
                Get-Partition -DiskNumber $Disk.DeviceId | Set-Partition -NewDriveLetter $DriveLetter
            }
        }
    }
}