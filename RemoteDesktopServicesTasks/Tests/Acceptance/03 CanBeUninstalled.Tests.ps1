#take the first trusted gallery to test against, otherwise the PSGallery. This is sufficient for this demo
$repository = Get-PSRepository | Where-Object InstallationPolicy -EQ Trusted -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $repository) {
    $repository = Get-PSRepository -Name PSGallery
}
$repositoryName = $repository.Name
$moduleName = $env:BHProjectName

Describe "Module '$moduleName' can be uninstalled" -Tags 'FunctionalQuality' {
    It 'Offers as least one DSC Resource' {
        { if (Get-InstalledModule -name $moduleName -ErrorAction SilentlyContinue) {
                Uninstall-Module -name $moduleName -ErrorAction stop
            } } | Should Not Throw
    }
}