function Add-CcmDatabaseUserAndRoles {
    [CmdletBinding()]
    [Alias('Add-DatabaseUserAndRoles')]
    param(
        [parameter(Mandatory)][string] $Username,
        [parameter(Mandatory)][string] $DatabaseName,
        [parameter()][string] $DatabaseServer = 'localhost\SQLEXPRESS',
        [parameter()] $DatabaseRoles = @('db_datareader'),
        [parameter()][string] $DatabaseServerPermissionsOptions = 'Trusted_Connection=true;',
        [parameter()][switch] $CreateSqlUser,
        [Alias("SqlUserPw")]
        [parameter()][string] $SqlUserPassword
    )

    $LoginOptions = "FROM WINDOWS WITH DEFAULT_DATABASE=[$DatabaseName]"
    if ($CreateSqlUser) {
        $LoginOptions = "WITH PASSWORD='$SqlUserPassword', DEFAULT_DATABASE=[$DatabaseName], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF"
    }

    $addUserSQLCommand = @"
USE [master]
IF EXISTS(SELECT * FROM msdb.sys.syslogins WHERE UPPER([name]) = UPPER('$Username'))
BEGIN
DECLARE @kill varchar(8000) = '';
SELECT @kill = @kill + 'kill ' + CONVERT(varchar(5), session_id) + ';' FROM sys.dm_exec_sessions WHERE UPPER([login_name]) = UPPER('$Username')
EXEC(@kill);
DROP LOGIN [$Username]
END

CREATE LOGIN [$Username] $LoginOptions

USE [$DatabaseName]
IF EXISTS(SELECT * FROM sys.sysusers WHERE UPPER([name]) = UPPER('$Username'))
BEGIN
DROP USER [$Username]
END

CREATE USER [$Username] FOR LOGIN [$Username]

"@

    foreach ($DatabaseRole in $DatabaseRoles) {
        $addUserSQLCommand += @"
ALTER ROLE [$DatabaseRole] ADD MEMBER [$Username]
"@
    }

    Write-Host "Adding $UserName to $DatabaseName with the following permissions: $($DatabaseRoles -Join ', ')"
    Write-Debug "running the following: \n $addUserSQLCommand"
    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = "server='$DatabaseServer';database='master';$DatabaseServerPermissionsOptions"
    $Connection.Open()
    $Command = New-Object System.Data.SQLClient.SQLCommand
    $Command.CommandText = $addUserSQLCommand
    $Command.Connection = $Connection
    $null = $Command.ExecuteNonQuery()
    $Connection.Close()
}