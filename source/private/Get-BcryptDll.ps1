function Get-BcryptDll {
    <#
        .Synopsis
            Finds the Bcrypt DLL if present, or downloads it if missing. Returns the full path to the DLL.
        .Example
            $BCryptDllPath = Get-BcryptDll
        .Example
            $BCryptDllPath = Get-BcryptDll -DestinationPath ~\Downloads
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        # The path to find the DLL within, or extract the DLL to if unfound.
        [Parameter(Position = 0)]
        [string]$DestinationPath = (Join-Path $PSScriptRoot "data\bcrypt.net.0.1.0")
    )
    end {
        if (-not (Test-Path $DestinationPath)) {
            $null = New-Item -Path $DestinationPath -ItemType Directory -Force
        }
        $ZipPath = Join-Path $env:TEMP 'bcrypt.net.0.1.0.zip'
        if (-not ($Files = Get-ChildItem $DestinationPath -Filter "BCrypt.Net.dll" -Recurse)) {
            if (-not (Test-Path $ZipPath)) {
                Invoke-WebRequest -Uri 'https://www.nuget.org/api/v2/package/BCrypt.Net/0.1.0' -OutFile $ZipPath -UseBasicParsing
            }
            Expand-Archive -Path $ZipPath -DestinationPath $DestinationPath
            $Files = Get-ChildItem $DestinationPath -Recurse
        }
        $Files.Where{$_.Name -eq 'BCrypt.Net.dll'}.FullName
    }
}