[CmdletBinding()]
param(
    $SemVer = $(
        if (Get-Command gitversion -EA 0) {
            gitversion /showvariable SemVer
        } else {
            "0.0.1"
        }
    )
)

# Ensure requirements are present
if (-not (Get-Module ModuleFast -ListAvailable)) {
    # https://github.com/JustinGrote/ModuleFast?tab=readme-ov-file#bootstrap-quick-start
    Invoke-WebRequest bit.ly/modulefast | Invoke-Expression
}
Install-ModuleFast -NoProfileUpdate

# Build
Build-Module -SemVer $SemVer -Passthru