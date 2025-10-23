class PackageDownload : PackageDependency {
    [bool]$Internalize
    [string]$Source

    PackageDownload ($InputObject) {
        $this.Id = $InputObject.Id
        $this.Version = $InputObject.Version
        $this.Internalize = $InputObject.Internalize -or $InputObject.psobject.properties.name -notcontains "Internalize"
        $this.Source = $InputObject.Source
    }

    PackageDownload ($Id, $Version, $Internalize, $Source) {
        $this.Id = $Id
        $this.Version = $Version
        $this.Internalize = $Internalize
        $this.Source = $Source
    }
}