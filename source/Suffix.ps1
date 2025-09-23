# Check for and configure FIPS enforcement, if required.
if (
    (Get-ItemPropertyValue -Path "HKLM:\System\CurrentControlSet\Control\Lsa\FipsAlgorithmPolicy" -Name Enabled) -eq 1 -and
    $env:ChocolateyInstall -and
    -not [bool]::Parse(([xml](Get-Content $env:ChocolateyInstall\config\chocolatey.config)).chocolatey.features.feature.Where{$_.Name -eq 'useFipsCompliantChecksums'}.Enabled)
) {
    Write-Warning -Message "FIPS is enabled on this system. Ensuring Chocolatey uses FIPS compliant checksums"
    Invoke-Choco feature enable --name='useFipsCompliantChecksums'
}