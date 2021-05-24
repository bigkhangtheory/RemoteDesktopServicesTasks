# ActiveDirectoryTasks

Windows PowerShell Desired State Configuration (DSC) provides a configuration platform that is based on open standards. This repo provides a structured project for building re-usable and composable **DSC Configurations** *(DSC Composite Resources)* used to manage and configure Active Directory Domain Services.

For information about the scripts that perform work described by Configurations, see the GitHub repo for [DSC Resources](http://github.com/powershell/dscresources).

## Value Proposition

The value we're looking to provide, is to `do something similar to DSC Resource for System or Service Configurations.`

We want to lower the bar of bootstrapping infrastructure with DSC, by re-using configurations of system or services that we have built and shared.

The value proposition model:
>For __Administrators starting with Configuration Management__
>
>Who __need to deploy systems or services in a systematic, consistent mannger__
>
>Our __configuration repository__ is __a re-usable build process for DSC configurations__
>
>That __transforms Configuration into re-usable and composable DSC Composite Resources__

## Intent

The intent is to:

- simplify the way to consume a shared configuration
- Allow direct re-use in new environment (no copy-paste/modification of DSC Config or data)
- reduce the _cost_ of sharing, by automating the scaffolding (plaster), testing (pester, PSSA, Integration tests), building (Composite Resource), publishing to our internal [Powershell repository](https://repo.windows.mapcom.local/nuget/powershell/)
- ensuring high quality, by allowing the use of a testing harness fit for TDD
- Allow Build tools, tasks and scripts to be more standardized and re-usable
- ensure quick and simple iterations during the development process

To achieve the intent, we should:
- provide a familiar scaffolding structure similar to PowerShell modules
- create a model that can be self contained (or bootstrap itself with minimum dependencies)
- Be CI/CD tool independant
- Declare Dependencies in Module Manifest for Pulling requirements from a gallery
- Embed default Configuration Data alongside configs
- Provides guidelines, conventions and design patterns (i.e. re-using Configuration Data)

# Authoring guidelines

The [DSC Resource repository](http://github.com/powershell/dscresources) includes guidance on authoring that is applicable to configurations as well.
For more information, visit the links below:

 - [Best practices](https://github.com/PowerShell/DscResources/blob/master/BestPractices.md)
 - [Style guidelines](https://github.com/PowerShell/DscResources/blob/master/StyleGuidelines.md)
 - [Maintainers](https://github.com/PowerShell/DscResources/blob/master/Maintainers.md)

### Repository Structure

```
CompositeResourceName
│   .gitignore
│   .gitlab-ci.yml
│   Build.ps1
│   CompositeResourceName.PSDeploy.ps1
│   PSDepend.Build.psd1
│   README.md
│
├───Build
│   ├───BuildHelpers
│   │       Invoke-InternalPSDepend.ps1
│   │       Resolve-Dependency.ps1
│   │       Set-PSModulePath.ps1
│   └───Tasks
│           CleanBuildOutput.ps1
│           CopyModule.ps1
│           Deploy.ps1
│           DownloadDscResources.ps1
│           Init.ps1
│           IntegrationTests.ps1
│           SetPsModulePath.ps1
│           TestReleaseAcceptance.ps1
│
├───BuildOutput
│   │   localhost_Configuration1.mof
│   │   localhost_Configuration2.mof
│   │   localhost_Configuration3.mof
│   │   localhost_ConfigurationN.mof
│   │ 
│   ├───Modules
│   │ 
│   └───Pester
│           IntegrationTestResults.xml
│
├───docs
│       Configuration1.md
│       Configuration2.md
│       Configuration3.md
│       ConfigurationN.md
│
└───CompositeResourceName
    │   CompositeResourceName.psd1
    │
    ├───DscResources
    │   ├───Configuration1
    │   │       Configuration1.psd1
    │   │       Configuration1.psm1
    │   │
    │   ├───Configuration2
    │   │       Configuration2.psd1
    │   │       Configuration2.psm1
    │   │
    │   ├───Configuration3
    │   │       Configuration3.psd1
    │   │       Configuration3.psm1
    │   │
    │   ├───ConfigurationN
    │   │       ConfigurationN.psd1
    │   │       ConfigurationN.psm1
    │   ...
    │
    └───Tests
        ├───Acceptance
        │       01 Gallery Available.Tests.ps1
        │       02 HasDscResources.Tests.ps1
        │       03 CanBeUninstalled.Tests.ps1
        │
        └───Integration
            │   01 DscResources.Tests.ps1
            │   02.Final.Tests.ps1
            │
            └───Assets
                │   AllNodes.yml
                │   Datum.yml
                │   TestHelpers.psm1
                │
                └───Config
                        Configuration1.yml
                        Configuration2.yml
                        Configuration3.yml
                        ConfigurationN.yml

```
The Composite Resource should be self contained, but will require files for building/testing or development.
The repository will hence need some project files on top of the files required for functionality.

Adopting the 2 layers structure like so:
```
+-- CompositeResourceName\
    +-- CompositeResourceName\
```
Allows to place Project files like build, CI configs and so on at the top level, and everything under the second level are the files that need to be shared and will be uploaded to the PSGallery.


Within that second layer, the Configuration looks like a standard module with some specificities.

### Configuration Data

The configuration data, IMO, should be managed in an 'override-only' way to preserve the cattle vs pet case. That is: 
- everything is standard (the standard/best practice data being shared alongside the configuration script), 
- but can be overriden in specific cases when required (overriding a domain name, certificate and so on).

This cannot be done out of the box (without tooling), but it's possible using custom scripts or module, as I intend to with the [Datum](https://github.com/gaelcolas/datum) module.

The challenge is then to manage the config data for a shared config in a way compatible with using a Configuration Data management module or function.

I see two possible approach:
- Conform with the most documented approach which is to cram properties under statically define values in hashtable: i.e. `$Node.Role.property` or `$AllNodes.Role.Property`, but that is very hacky or does not scale
- Introduce the less documented, more flexible way to resolve a property for the current Node via a function: i.e. `Resolve-DscProperty -Node $Node -PropertyPath 'Role\Property'`

The second one is more flexible (anyone can create their custom one), but probably needs some time and a lot of communication before taking precedence over the static way.

We could [provide a standard, simple function](./SharedDscConfig/examples/scripts/Resolve-DscConfigurationData.ps1) to resolve the static properties when creating Shareable configurations, where the logic can be overriden where consuming that shared configuration.

```PowerShell
function Resolve-DscConfigurationData {
    Param(
        [hashtable]$Node,
        [string]$PropertyPath,
        [AllowNull()]
        $Default
    )

    $paths = $PropertyPath -split '\\'
    $CurrentValue = $Node
    foreach ($path in $Paths) {
        $CurrentValue = $CurrentValue.($path)
    }

    if ($null -eq $CurrentValue -and !$PSBoundParameters.ContainsKey('Default')) {
        Throw 'Property returned $null but no default specified.'
    }
    elseif ($CurrentValue) {
        Write-Output $CurrentValue
    }
    else {
        Write-Output $Default
    }
}
Set-Alias -Name ConfigData -value Resolve-DscConfigurationData
Set-Alias -Name DscProperty -value Resolve-DscConfigurationData
```

This Allows to resolve static data so that: 
```PowerShell
DscProperty -Node @{
        NodeName='localhost';
        a=@{
            b=122
        }
    } -PropertyPath 'a\b'
```
Resolves to `122`, but another implementation of Resolve-DscConfigurationData could do a database lookup in the company's CMDB for instance.

Doing so would allow to have functions to lookup for Configuration Data from the Shared Configuration, or from custom overrides.

### Root Tree
The root of the tree would be similar to a module root tree where you have supporting files for, say, the CI/CD integration.

In this example, I'm illustrating the idea with:
- a Build.ps1 that defines the build workflow by composing tasks (see [SampleModule](https://github.com/gaelcolas/SampleModule))
- a Build/ folder, which includes the minimum tasks to bootstrap + custom ones
- the .gitignore where folders like BuildOutput or kitchen specific files are added (`module/`)
- the [PSDepend.Build.psd1](./PSDepend.Build.ps1), so that the build process can use [PSDepend](https://github.com/RamblingCookieMonster/PSDepend/) to pull any prerequisites to build this project
- the Gitlab runner configuration file 


## Configuration Module Folder

Very similar to a PowerShell Module folder, the Shared configuration re-use the same principles and techniques.

The re-usable configuration itself is declared in the ps1, the metadata and dependencies in the psd1 to leverage all the goodies of module management, then we have some assets ordered in folders:
- ConfigurationData: the default/example configuration data, organised in test suite/scenarios
- Test Acceptance & Integration: the pester tests used to validate the configuration, per test suite/scenario
- the examples of re-using that shared configuration, per test suite/scenario

## YAML Reference Documentation

The [YAML reference documentation](./doc/README.adoc) is located in the ./doc subfolder of this repository.
