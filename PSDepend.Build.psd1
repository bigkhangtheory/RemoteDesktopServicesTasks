@{

    PSDependOptions              = @{
        AddToPath      = $true
        Target         = 'BuildOutput\Modules'
        DependencyType = 'PSGalleryModule'
        Parameters     = @{
            Repository = 'PSGallery'
        }
    }

    # -------------------------------------------------------------------------
    # PowerShell Modules
    # -------------------------------------------------------------------------
    
    BuildHelpers                 = 'latest'
    # Helper functions for PowerShell CI/CD scenarios

    Datum                        = '0.39.0'
    # Module to manage Hierachical Configuration Data

    'Datum.InvokeCommand'       = '0.1.2'
    # Datum Handler module to encrypt and decrypt secrets in Datum using Dave Wyatt's ProtectedData module

    'Datum.ProtectedData'        = 'latest'
    # Datum Handler module to encrypt and decrypt secrets in Datum using Dave Wyatt's ProtectedData module

    DscBuildHelpers              = 'latest'
    # Build Helpers for DSC Resources and Configurations

    InvokeBuild                  = 'latest'
    # Build and test automation in PowerShell

    Pester                       = '4.10.1'
    # Pester provides a framework for running BDD style Tests to execute and validate PowerShell commands inside of PowerShell.
    # It offers a powerful set of Mocking Functions that allow tests to mimic and mock the functionality of any command inside of a piece of PowerShell code being tested.
    # Pester tests can execute any command or script that is accessible to a pester test file. This can include functions, Cmdlets, Modules and scripts.
    # Pester can be run in ad hoc style in a console or it can be integrated into the Build scripts of a Continuous Integration system.

    'posh-git'                   = 'latest'
    # Provides prompt with Git status summary information and tab completion for Git commands, parameters, remotes and branch names.

    'powershell-yaml'            = 'latest'
    # Powershell module for serializing and deserializing YAML

    ProtectedData                = 'latest'
    # Encrypt and share secret data between different users and computers.

    PSScriptAnalyzer             = 'latest'
    # Provides script analysis and checks for potential code defects in the scripts by applying a group of built-in or customized rules on the scripts being analyzed.

    PSDeploy                     = 'latest'
    # Module to simplify PowerShell based deployments

    # -------------------------------------------------------------------------
    # DSC Resources
    # -------------------------------------------------------------------------
    
    ActiveDirectoryDsc           = '6.0.1'
    # Contains DSC resources for deployment and configuration of Active Directory.
    # These DSC resources allow you to configure new domains, child domains, and high availability domain controllers, establish cross-domain trusts and manage users, groups and OUs.

    xPSDesiredStateConfiguration = '9.1.0'
    ComputerManagementDsc        = '8.4.0'
    NetworkingDsc                = '8.2.0'
    JeaDsc                       = '0.7.2'
    XmlContentDsc                = '0.0.1'
    xWebAdministration           = '3.2.0'
    SecurityPolicyDsc            = '2.10.0.0'
    StorageDsc                   = '5.0.1'
    Chocolatey                   = '0.0.79'
    DfsDsc                       = '4.4.0.0'
    WdsDsc                       = '0.11.0'
    xDhcpServer                  = '3.0.0'
    xDscDiagnostics              = '2.8.0'
    xDnsServer                   = '2.0.0'
    xFailoverCluster             = '1.16.0'
    GPRegistryPolicyDsc          = '1.2.0'
    AuditPolicyDsc               = '1.4.0.0'
    SqlServerDsc                 = '15.1.1'
    UpdateServicesDsc            = '1.2.1'
    xWindowsEventForwarding      = '1.0.0.0'
    xBitlocker                   = '1.4.0.0'
    ActiveDirectoryCSDsc         = '5.0.0'
}
