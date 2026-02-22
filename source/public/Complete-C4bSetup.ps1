function Complete-C4bSetup {
    param(
        [switch]$SkipBrowserLaunch
    )
    # Setup Agent on this machine
    if (-not (Get-Service chocolatey-agent -ErrorAction SilentlyContinue)) {
        Invoke-Choco install chocolatey-agent --confirm
        Invoke-Choco feature enable --name='useChocolateyCentralManagement'
        Invoke-Choco feature enable --name='useChocolateyCentralManagementDeployments'
    }

    # Write readme to desktop and hand over to user
    Write-Host 'Writing README to Desktop - this file contains login information for all C4B services.'
    New-QuickstartReadme

    if (-not $SkipBrowserLaunch -and $Host.Name -eq 'ConsoleHost') {
        $Message = 'The CCM, Nexus & Jenkins sites will open in your browser in 10 seconds. Press any key to skip this.'
        $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        Write-Host $Message -NoNewline -ForegroundColor Green
        do {
            # wait for a key to be available:
            if ([Console]::KeyAvailable) {
                # read the key, and consume it so it won't
                # be echoed to the console:
                $keyInfo = [Console]::ReadKey($true)
                Write-Host "`nSkipping the Opening of sites in your browser." -ForegroundColor Green
                # exit loop
                break
            }
            # write a dot and wait a second
            Write-Host '.' -NoNewline -ForegroundColor Green
            Start-Sleep -Seconds 1
        } while ($Stopwatch.Elapsed.TotalSeconds -lt 10)

        if (-not ($keyInfo)) {
            Write-Host "`nOpening administration sites in your browser." -ForegroundColor Green
            Start-Process msedge.exe @(
                'file:///C:/Users/Public/Desktop/README.html',
                (Get-ChocoEnvironmentProperty CCMWebPortal),
                (Get-ChocoEnvironmentProperty ProGetUri),
                (Get-ChocoEnvironmentProperty NexusUri),
                (Get-ChocoEnvironmentProperty PowerShellUniversalUri),
                (Get-ChocoEnvironmentProperty JenkinsUri)
            ).Where{ $_ }
        }
    }
}