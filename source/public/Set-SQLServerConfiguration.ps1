function Set-SqlServerConfiguration {
    [CmdletBinding()]
    param(
        [Parameter()]
        [String]
        $SqlTcpPort = '1433',

        [Parameter()]
        [String]
        $SqlUdpPort = '1434',

        [Parameter()]
        [String]
        $SqlVersion = '16'
    )
    # https://docs.microsoft.com/en-us/sql/tools/configuration-manager/tcp-ip-properties-ip-addresses-tab
    Write-Output "SQL Server: Configuring Remote Access on SQL Server Express."
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
    $tcpPort.Value = $SqlTcpPort
    $tcp.Alter()

    # TODO: THIS LINE IS VERSION DEPENDENT! Replace MSSQL16 with whatever version you have
    Write-Output "SQL Server: Setting Mixed Mode Authentication."
    New-ItemProperty $('HKLM:\Software\Microsoft\Microsoft SQL Server\MSSQL{0}.SQLEXPRESS\MSSQLServer\' -f $SqlVersion) -Name 'LoginMode' -Value 2 -Force
    # VERSION DEPENDENT ABOVE

    Write-Output "SQL Server: Forcing Restart of Instance."
    Restart-Service -Force 'MSSQL$SQLEXPRESS'

    Write-Output "SQL Server: Setting up SQL Server Browser and starting the service."
    Set-Service 'SQLBrowser' -StartupType Automatic
    Start-Service 'SQLBrowser'

    Write-Output "Firewall: Enabling SQLServer TCP port $SqlTcpPort."
    netsh advfirewall firewall add rule name="SQL Server $SqlTcpPort" dir=in action=allow protocol=TCP localport=1433 profile=any enable=yes service=any

    Write-Output "Firewall: Enabling SQL Server browser UDP port $SqlUdpPort."
    netsh advfirewall firewall add rule name="SQL Server Browser $SqlUdpPort" dir=in action=allow protocol=UDP localport=$SqlUdpPort profile=any enable=yes service=any
}