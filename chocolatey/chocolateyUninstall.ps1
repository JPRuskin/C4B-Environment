$modulePath = Join-Path -Path $env:ProgramFiles -ChildPath WindowsPowerShell\Modules
$targetDirectory = Join-Path -Path $modulePath -ChildPath "C4B-Environment"
$sourceDirectory = Join-Path -Path $PSScriptRoot -ChildPath module

if ($PSVersionTable.PSVersion.Major -ge 5) {
    $manifestFile = Join-Path -Path $sourceDirectory -ChildPath C4B-Environment.psd1
    $manifest = Test-ModuleManifest -Path $manifestFile -WarningAction Ignore -ErrorAction Stop
    $targetDirectory = Join-Path -Path $targetDirectory -ChildPath $manifest.Version.ToString()
}

Remove-Item $targetDirectory -Recurse