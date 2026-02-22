function Invoke-Choco {
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string]$Command,

        [Parameter(Position=1, ValueFromRemainingArguments)]
        [string[]]$Arguments,

        [int[]]$ValidExitCodes = @(0)
    )

    if ($Command -eq 'Install' -or $Command -eq 'Upgrade' -and $Arguments -notmatch '\b-(y|-confirm)\b') {
        $Arguments += '--confirm'
    }

    if ($Arguments -notmatch '\b-(r|-limitoutput|-limit-output)\b') {
        $Arguments += '--limit-output'
    }

    if ($ErrorActionPreference -eq 'Stop') {
        $Arguments += '--fail-on-error-output'
    }

    $chocoPath = if ($CommandPath = Get-Command choco.exe -ErrorAction SilentlyContinue) {
        $CommandPath.Source
    } elseif ($env:ChocolateyInstall) {
        Join-Path $env:ChocolateyInstall "choco.exe"
    } elseif (Test-Path C:\ProgramData\chocolatey\choco.exe) {
        "C:\ProgramData\chocolatey\choco.exe"
    } else {
        Write-Error "Could not find 'choco.exe' - unexpected behaviour is expected!"
        "choco.exe"
    }

    try {
        & $chocoPath $Command $Arguments | Tee-Object -Variable Result | Where-Object { $_ } | ForEach-Object {
            Write-Information -MessageData $_ -Tags Choco
        }
    } finally {
        if ($LASTEXITCODE -notin $ValidExitCodes) {
            Write-Error -Message "$(([string[]]$Result)[-5..-1] -join "`n")`nFor more information, see: $(Resolve-Path $env:ChocolateyInstall\logs\chocolatey.log)" -TargetObject "choco $Command $Arguments"
        }
    }
}