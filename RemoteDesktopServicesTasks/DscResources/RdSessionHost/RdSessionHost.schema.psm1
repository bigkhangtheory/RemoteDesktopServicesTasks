configuration RdSessionHost
{
    <#
    .SYNOPSIS
        This DSC Configuration adds an RD Session Host to a RDS Collection
    .PARAMETER ConnectBrokerFqdn
        This specifies the RD Connection Broker FQDN of the deployment in which to join this session host to
    .PARAMETER WebAccessServerFqdn
        This specifies the RD Web Access FQDN of the deployment in which to join this host to.
    .PARAMETER CollectionName
        This specifies the RDS Session Collection name to join.
    .PARAMETER CollectionDescription
        This specified the RDS Session Collection description to be included.
#>
    param (
        [Parameter()]
        [System.String]
        $ConnectionBrokerFqdn,

        [Parameter()]
        [System.String]
        $WebAccessServerFqdn,

        [Parameter()]
        [System.String]
        $CollectionName,

        [Parameter()]
        [System.String]
        $CollectionDescription,

        [Parameter()]
        [System.Collections.Hashtable]
        $CollectionConfiguration
    )

    Import-DscResource -Module PSDesiredStateConfiguration
    Import-DscResource -Module xRemoteDesktopSessionHost

    # retrieve hostname of this node
    $localhost = [System.Net.Dns]::GetHostByName((hostname)).HostName

    # if the Connect Broker and Web Access servers are not specified, then assume this node
    if ($null -eq $ConnectionBrokerFqdn) { $ConnectionBrokerFqdn = $localhost }
    if ($null -eq $WebAccessServerFqdn) { $WebAccessServerFqdn = $localhost }

    # configuration required Windows Features
    WindowsFeature desktopExperience
    {
        Name   = 'Desktop-Experience'
        Ensure = 'Present'
    }
    WindowsFeature remoteDesktopServices
    {
        Name   = 'Remote-Desktop-Services'
        Ensure = 'Present'
    }
    WindowsFeature rdsRDServer
    {
        Name   = 'RDS-RD-SERVER'
        Ensure = 'Present'
    }
    WindowsFeature rsatRDSTools
    {
        Name                 = 'RSAT-RDS-Tools'
        Ensure               = 'Present'
        IncludeAllSubFeature = $true
    }
    $dependsOnWindowsFeature = @(
        '[WindowsFeature]desktopExperience', '[WindowsFeature]remoteDesktopServices', '[WindowsFeature]rdsRDServer', '[WindowsFeature]rsatRDSTools'
    )

    # if Connection Broker is not specified, configure this node
    if ($localhost -eq $ConnectionBrokerFqdn)
    {
        WindowsFeature rdsConnectionBroker
        {
            Name   = 'RDS-Connection-Broker'
            Ensure = 'Present'
        }
        $dependsOnWindowsFeature.Add('[WindowsFeature]rdsConnectionBroker')
    }

    # if Web Access server is not specifed, configure this node
    if ($localhost -eq $WebAccessServerFqdn)
    {
        WindowsFeature rdsWebAccess
        {
            Name   = 'RDS-Web-Access'
            Ensure = 'Present'
        }
        $dependsOnWindowsFeature.Add('[WindowsFeature]rdsWebAccess')
    }

    # create and configure an RDS deployment with this node
    xRDSessionDeployment "deployment_$($localhost -replace '[().:\s]', '')"
    {
        SessionHost      = $localhost
        ConnectionBroker = if ($ConnectionBrokerFqdn) { $ConnectionBrokerFqdn } else { $localhost }
        WebAccessServer  = if ($ConnectionBrokerFqdn) { $WebAccessServerFqdn } else { $localhost }
        DependsOn        = $dependsOnWindowsFeature
    }
    $dependsOnRDSessionDeployment = "[xRDSessionDeployment]deployment_$($localhost -replace '[().:\s]', '')"


    # create and configure an RDS Session Collection with this node
    xRDSessionCollection "collection_$($localhost -replace '[().:\s]', '')"
    {
        CollectionName        = $CollectionName
        CollectionDescription = $CollectionDescription
        SessionHost           = $localhost
        ConnectionBroker      = if ($ConnectionBrokerFqdn) { $ConnectionBrokerFqdn } else { $localhost }
        DependsOn             = $dependsOnRDSessionDeployment
    }
    $dependsOnRDSessionCollection = "[xRDSessionCollection]collection_$($localhost -replace '[().:\s]', '')"

    # if specified, apply RDS Session collection configurations
    if ($CollectionConfiguration)
    {
        if ($CollectionConfiguration.UserGroup)
        {
            $myGroups = [System.Text.StringBuilder]::new()
            foreach ($group in $CollectionConfiguration.UserGroup)
            {
                $myGroups.Append( '{0} ' -f $group)
            }
            $myGroups.ToString()
        }

        xRDSessionCollectionConfiguration "configuration_$($CollectionName -replace '[().:\s]', '')"
        {
            CollectionName                 = $CollectionName
            ConnectionBroker               = if ($ConnectionBrokerFqdn) { $ConnectionBrokerFqdn } else { $localhost }
            UserGroup                      = $myGroups
            ActiveSessionLimitMin          = $CollectionConfiguration.ActiveSessionLimitMin
            DisconnectedSessionLimitMin    = $CollectionConfiguration.DisconnectedSessionLimitMin
            IdleSessionLimitMin            = $CollectionConfiguration.IdleSessionLimitMin
            AuthenticateUsingNLA           = $CollectionConfiguration.AuthenticateUsingNLA
            AutomaticReconnectionEnabled   = $CollectionConfiguration.AutomaticReconnectionEnabled
            BrokenConnectionAction         = $CollectionConfiguration.BrokenConnectionAction
            ClientDeviceRedirectionOptions = $CollectionConfiguration.ClientDeviceRedirectionOptions
            ClientPrinterAsDefault         = $CollectionConfiguration.ClientPrinterAsDefault
            ClientPrinterRedirected        = $CollectionConfiguration.ClientPrinterRedirected
            EncryptionLevel                = $CollectionConfiguration.EncryptionLevel
            MaxRedirectedMonitors          = $CollectionConfiguration.MaxRedirectedMonitors
            SecurityLayer                  = $CollectionConfiguration.SecurityLayer
            TemporaryFoldersDeletedOnExit  = $CollectionConfiguration.TemporaryFoldersDeletedOnExit
            EnableUserProfileDisk          = $CollectionConfiguration.EnableUserProfileDisk
            DiskPath                       = $CollectionConfiguration.DiskPath
            MaxUserProfileDiskSizeGB       = $CollectionConfiguration.MaxUserProfileDiskSizeGB
            DependsOn                      = $dependsOnRDSessionCollection
        }
    }
}