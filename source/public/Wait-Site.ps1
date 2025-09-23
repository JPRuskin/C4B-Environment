function Wait-Site {
    <#
        .Synopsis
            Waits for a given site to be available. A simple healthcheck.
    #>
    [Alias('Wait-Nexus','Wait-CCM','Wait-Jenkins')]
    [CmdletBinding(DefaultParameterSetName="Name")]
    param(
        # The service name to check for a 200 response
        [Parameter(ParameterSetName='Name', Position=0)]
        [ValidateSet('Nexus','CCM','Jenkins')]
        [string]$Name = $MyInvocation.InvocationName.Split('-')[-1],

        # The Url to check for a 200 response
        [Parameter(ParameterSetName='Url', Mandatory, Position=0)]
        [string]$Url = @{
            'Nexus'   = {
                try {
                    Get-NexusLocalServiceUri
                } catch {
                    Write-Verbose "Nexus may not be installed yet."
                    "http://localhost:8081"
                }
            }
            'CCM'     = {
                try {
                    $Binding = Get-WebBinding -Name ChocolateyCentralManagement
                    $Domain = if (
                        $Binding.protocol -eq 'https' -and
                        ($Certificate = Get-ChildItem Cert:\LocalMachine\TrustedPeople | Where-Object Subject -notlike 'CN=`**').Count -eq 1 -and
                        $Certificate.Subject -match "^CN=(?<Domain>.+)(?:,|$)"
                    ) {
                        $Matches.Domain
                    } elseif ($Binding.protocol -eq 'https' -and ($CertSubject = Get-ChocoEnvironmentProperty CertSubject)) {
                        $CertSubject
                    } else {
                        'localhost'
                    }
                    "$($Binding.protocol)://$($Domain):$($Binding.bindingInformation.Trim('*').Trim(':'))/"
                } catch {
                    Write-Verbose "CCM may not be installed yet."
                    "http://localhost"
                }
            }
            'Jenkins' = {
                try {
                    if (Test-Path "C:\Program Files\Jenkins\jenkins.xml") {
                        [xml]$Xml = Get-Content "C:\Program Files\Jenkins\jenkins.xml"
                        if ($Xml.SelectSingleNode("/service/arguments").'#text' -match "--(?<Scheme>https?)Port=(?<PortNumber>\d+)\b") {
                            $Port = $Matches.PortNumber
                            $Scheme = $Matches.Scheme
                        }
                        $Domain = if ($Scheme -eq 'https') {
                            Get-ChocoEnvironmentProperty CertSubject
                        } else {
                            'localhost'
                        }
                        "$($Scheme)://$($Domain):$($Port)/login"  # TODO: Get PATH
                    } elseif (Test-Path "C:\Program Files\Jenkins\jenkins.model.JenkinsLocationConfiguration.xml") {
                        [xml]$Location = (Get-Content "C:\Program Files\Jenkins\jenkins.model.JenkinsLocationConfiguration.xml" -ErrorAction Stop) -replace "^\<\?xml version=['""]1\.1['""]","<?xml version='1.0'"
                        $Location."jenkins.model.JenkinsLocationConfiguration".jenkinsUrl
                    }
                } catch {
                    Write-Verbose "Jenkins may not be installed yet."
                    "http://$('localhost'):8080/login"
                }
            }
        }.$Name.Invoke(),

        # Seconds before we give up waiting and fail
        [uint16]$Timeout = 180  # seconds
    )
    begin {
        $Timer = [System.Diagnostics.Stopwatch]::StartNew()

        if ([string]::IsNullOrEmpty($Url)) {
            Write-Error "Please pass a valid -Name or -Url to wait for." -ErrorAction Stop
        }
    }
    end {
        while ($Response.StatusCode -ne '200' -and $Timer.Elapsed.TotalSeconds -lt $Timeout) {
            $Response = try {
                Invoke-WebRequest $Url -UseBasicParsing -ErrorAction Stop
            } catch { $null }
        }

        if ($Response.StatusCode -eq '200') {
            Write-Verbose "'$($Url)' is accessible!"
        } else {
            Write-Error "'$($Url)' was not accessible after $($Timer.Elapsed.TotalSeconds) seconds." -ErrorAction Stop
        }
    }
}