function Start-CcmService {
    try {
        Start-Service chocolatey-central-management -ErrorAction Stop
    }
    catch {
        #Try again...
        Start-Service chocolatey-central-management -ErrorAction SilentlyContinue
    }
    finally {
        if ((Get-Service chocolatey-central-management).Status -ne 'Running') {
            Write-Warning "Unable to start Chocolatey Central Management service, please start manually in Services.msc"
        }
    }

}