function Set-ClientScriptDefaultParameterValue {
    <#
        .Synopsis
            Replaces the default values stored in a script or function file.

        .Description
            This function reads a script or function file, finds likely parameter keys
            with or without default values, and replaces or adds a value as appropriate.

        .Example
            Set-ClientScriptDefaultParameterValue -Path $ClientSetup -Replacements @{HostName = $CcmFQDN}

            # Replaces the hostname default value with the value in $CcmFQDN

        .Example
            Set-ClientScriptDefaultParameterValue -Path $ClientSetup -Replacements @{Credential = {Get-Credential Administrator}}

            # Replaces the Credential default value with a subexpression containing the provided scriptblock.

        .Example
            Set-ClientScriptDefaultParameterValue -Path $ClientSetup -Replacements @{HostName = 'ccm.example.org'}

            # Replaces the hostname default value with the value provided.
    #>
    [CmdletBinding()]
    param(
        # The path to the script file to make replacements in.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('PSPath')]
        [string[]]$Path,

        # A hashtable of replacements, where the key is the name of the parameter and the value is the new default value.
        [hashtable]$Replacements,

        # Recurse into nested scriptblocks for, e.g. files containing nested functions.
        [switch]$Recurse
    )
    process {
        foreach ($File in $Path) {
            $ScriptAst = (Get-Command $File).ScriptBlock.Ast
            $Regions = foreach ($ParameterName in $Replacements.Keys) {
                $FoundParameter = $ScriptAst.FindAll(
                    {
                        $args[0] -is [System.Management.Automation.Language.ParameterAst] -and
                        $args[0].Name.VariablePath.UserPath -eq $ParameterName
                    },
                    $Recurse
                )

                foreach ($Parameter in $FoundParameter) {
                    Write-Verbose "Extent: $($FoundParameter | ConvertTo-Json -Depth 1)"

                    [PSCustomObject]@{
                        Start = $Parameter.DefaultValue.Extent.StartOffset # $ParameterDefinition.Extent.EndScriptPosition.Offset
                        Value = $Replacements.$ParameterName
                        End   = $Parameter.DefaultValue.Extent.EndOffset  # $Parameter.Extent.EndOffset
                    }
                }
            }

            $FileContent = $ScriptAst.Extent.Text
            foreach ($Region in $Regions | Sort-Object Start -Descending) {
                Write-Verbose "Replacing $($Region | ConvertTo-Json)"
                $FileContent = -join @(
                    (-join$FileContent[0..$($Region.Start - 1)]).TrimEnd(' =')
                    ' = '
                    if ($Region.Value -is [string] -and ($Region.Value -match '\W' -or -not $Region.Value.StartsWith('$'))) {
                        """$($Region.Value)"""
                    } elseif ($Region.Value -is [scriptblock]) {
                        '$(' + $Region.Value + ')'
                    } else {
                        $Region.Value
                    }
                    $FileContent[$($Region.End)..$($FileContent.Length)]
                )
            }

            Set-Content -Value $FileContent -Path $File
        }
    }
}