function Set-CcmSqlServerAccess {
    [CmdletBinding()]
    param()
    # https://docs.microsoft.com/en-us/sql/tools/configuration-manager/tcp-ip-properties-ip-addresses-tab
    Write-Verbose 'SQL Server: Configuring Remote Access on SQL Server Express.'
    $assemblyList = 'Microsoft.SqlServer.Management.Common', 'Microsoft.SqlServer.Smo', 'Microsoft.SqlServer.SqlWmiManagement', 'Microsoft.SqlServer.SmoExtended'

    foreach ($assembly in $assemblyList) {
        $assembly = [System.Reflection.Assembly]::LoadWithPartialName($assembly)
    }

    $wmi = New-Object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer # connects to localhost by default
    $instance = $wmi.ServerInstances | Where-Object { $_.Name -eq 'SQLEXPRESS' }

    $np = $instance.ServerProtocols | Where-Object { $_.Name -eq 'Np' }
    $np.IsEnabled = $true
    $np.Alter()

    $tcp = $instance.ServerProtocols | Where-Object { $_.Name -eq 'Tcp' }
    $tcp.IsEnabled = $true
    $tcp.Alter()

    $tcpIpAll = $tcp.IpAddresses | Where-Object { $_.Name -eq 'IpAll' }

    $tcpDynamicPorts = $tcpIpAll.IpAddressProperties | Where-Object { $_.Name -eq 'TcpDynamicPorts' }
    $tcpDynamicPorts.Value = ""
    $tcp.Alter()

    $tcpPort = $tcpIpAll.IpAddressProperties | Where-Object { $_.Name -eq 'TcpPort' }
    $tcpPort.Value = "1433"
    $tcp.Alter()

    # This section will evaluate which version of SQL Express you have installed, and set a login value accordingly
    $SqlString = (Get-ChildItem -Path 'HKLM:\Software\Microsoft\Microsoft SQL Server').Name |
        Where-Object { $_ -like "HKEY_LOCAL_MACHINE\Software\Microsoft\Microsoft SQL Server\MSSQL*.SQLEXPRESS" }
    $SqlVersion = $SqlString.Split("\") | Where-Object { $_ -like "MSSQL*.SQLEXPRESS" }
    Write-Verbose 'SQL Server: Setting Mixed Mode Authentication.'
    $null = New-ItemProperty "HKLM:\Software\Microsoft\Microsoft SQL Server\$SqlVersion\MSSQLServer\" -Name 'LoginMode' -Value 2 -Force

    Write-Verbose "SQL Server: Forcing Restart of Instance."
    Restart-Service -Force 'MSSQL$SQLEXPRESS'

    Write-Verbose "SQL Server: Setting up SQL Server Browser and starting the service."
    Set-Service 'SQLBrowser' -StartupType Automatic
    Start-Service 'SQLBrowser'

    Write-Verbose "Firewall: Enabling SQLServer TCP port 1433."
    $null = netsh advfirewall firewall add rule name="SQL Server 1433" dir=in action=allow protocol=TCP localport=1433 profile=any enable=yes service=any
    #New-NetFirewallRule -DisplayName "Allow inbound TCP Port 1433" –Direction inbound –LocalPort 1433 -Protocol TCP -Action Allow

    Write-Verbose "Firewall: Enabling SQL Server browser UDP port 1434."
    $null = netsh advfirewall firewall add rule name="SQL Server Browser 1434" dir=in action=allow protocol=UDP localport=1434 profile=any enable=yes service=any
}