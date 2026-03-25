function Set-EnvFirewallRule {
    [OutputType([void])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DisplayName,

        [string]$Direction = "Inbound",

        [Parameter(Mandatory)]
        [uint16]$LocalPort,

        [string]$Protocol = "TCP",

        [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetSecurity.Action]$Action = "Allow"
    )
    if ($ExistingRule = Get-NetFirewallRule -DisplayName $DisplayName) {
        $ExistingRule | Set-NetFirewallRule -Direction $Direction -LocalPort $LocalPort -Protocol $Protocol -Action $Action
    } else {
        $null = New-NetFirewallRule @PSBoundParameters
    }
}