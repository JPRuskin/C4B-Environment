function Remove-CcmBinding {
    [CmdletBinding()]
    param()

    process {
        Write-Verbose "Removing existing bindings"
        netsh http delete sslcert ipport=0.0.0.0:443 | Write-Verbose
    }
}