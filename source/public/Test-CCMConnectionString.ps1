function Test-CcmConnectionString {
    <#
        .Synopsis
            Tests your connection string can connect to the instance in question

        .Example
            Test-CcmConnectionString -ConnectionString $ConnectionString
    #>
    [cmdletBinding()]
    param(
        # The connection string to test
        [Parameter(Mandatory, Position = 0)]
        [String]$ConnectionString
    )
    try {
        # This throws an error if it fails to connect, and outputs the reason
        $Connection = [System.Data.SQLClient.SqlConnection]::new($ConnectionString)
        $Connection.Open()

        if ($Connection.State -eq 'Open') {
            Write-Verbose "Connection successfully established"
        }
    } finally {
        $Connection.Close()
        $Connection.Dispose()
    }
}