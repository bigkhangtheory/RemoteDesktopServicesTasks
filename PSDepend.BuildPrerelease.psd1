
@{

    PSDependOptions = @{
        AddToPath      = $true
        Target         = 'BuildOutput\Modules'
        DependencyType = 'PSGalleryModule'
        Parameters     = @{
            Repository      = 'PSGallery'
            AllowPreRelease = $true
        }
    }

}