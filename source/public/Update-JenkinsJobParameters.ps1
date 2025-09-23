function Update-JenkinsJobParameters {
    param(
        [string]$JobsPath = "C:\ProgramData\Jenkins\.jenkins\jobs",

        [hashtable]$Replacement = @{}
    )
    process {
        foreach ($Job in Get-ChildItem $JobsPath -Filter config.xml -Recurse) {
            Write-Verbose "Updating parameters in '$($Job.DirectoryName)'"
            [xml]$Config = (Get-Content $Job.FullName) -replace "^\<\?xml version=['""]1\.1['""]","<?xml version='1.0'"

            foreach ($Node in $Config.SelectSingleNode("//parameterDefinitions").ChildNodes) {
                if ($Node.name -in $Replacement.Keys) {
                    $Node.defaultValue = $Replacement[$Node.name]
                }
            }

            $Config.Save($Job.FullName)
        }
    }
}