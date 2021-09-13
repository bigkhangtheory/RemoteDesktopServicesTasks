<#
    .DESCRIPTION
        This DSC configuration manages an Remote Desktop Services deployment.
#>
#Requires -Module xPSDesiredStateConfiguration
#Requires -Module xRemoteDesktopSessionHost

configuration RemoteDesktopServices 
{
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $RDConnectionBroker,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $RDGateway,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $RDLicensing,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $RDWebAccess,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $RDSessionHost
    )

    <#
        Import required modules
    #>
    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName xRemoteDesktopSessionHost
    Import-Module -Name RemoteDesktop

    <#
        Install Windows features
    #>
    xWindowsFeature AddWindowsInternalDatabase
    {
        Name   = 'Windows-Internal-Database'
        Ensure = 'Present'
    }
    xWindowsFeature AddRdsConnectionBroker
    {
        Name      = 'RDS-Connection-Broker'
        Ensure    = 'Present'
        DependsOn = '[xWindowsFeature]AddWindowsInternalDatabase'
    }
    xWindowsFeature AddRsatRdsTools
    {
        Name                 = 'RSAT-RDS-Tools'
        Ensure               = 'Present'
        IncludeAllSubFeature = $true
    }

    <#
        The configuration must be applied on the active Connection Broker is exist.
    #>
    $localHost = [System.Net.Dns]::GetHostByName(($node.Name)).HostName

    $HA = Get-RDConnectionBrokerHighAvailability

    if ($null -eq $HA)
    {
        $activeConnectionBroker = $env:ComputerName
    }
    else
    {
        $activeConnectionBroker = $HA.ActiveManagementServer
    } 

    # this configuration should only be applied to the active Connection Broker in a highly available deployment
    if ($env:ComputerName -eq $activeConnectionBroker)
    {
        <# --------------------------------------------------------------------
            If specified, add RDS Connection Brokers
        #> 
        if ($RDConnectionBroker)
        {
            # iterate each entry and add
            foreach ($c in $RDConnectionBroker)
            {
                # create execution name for the resource
                $executionName = "ConnectionBroker_$($c -replace '[-().:\s]', '_')"

                # evaluate the FQDN of the named server
                $c = [System.Net.Dns]::GetHostByName("$c").HostName

                # create DSC Resource for RD Connection Broker
                xRDServer $executionName
                {
                    ConnectionBroker = $localHost
                    Server           = $c
                    Role             = 'RDS-Connection-Broker'
                    DependsOn        = '[xWindowsFeature]AddRdsConnectionBroker'
                } #end xRDServer
            } #end foreach
        } #end if ($RDConnectionBroker)


        <# --------------------------------------------------------------------
            If specified, add RDS Gateway servers
        #> 
        if ($RDGateway)
        {
            # iterate each entry and add
            foreach ($g in $RDGateway)
            {
                # create execution name for the resource
                $executionName = "Gateway_$($g -replace '[-().:\s]', '_')"

                # evaluate the FQDN of the named server
                $g = [System.Net.Dns]::GetHostByName("$g").HostName

                # create DSC Resource for RD Connection Broker
                xRDServer $executionName
                {
                    ConnectionBroker = $localHost
                    Server           = $g
                    Role             = 'RDS-Gateway'
                    DependsOn        = '[xWindowsFeature]AddRdsConnectionBroker'
                } #end xRDServer
            } #end foreach
        } #end if ($RDGateway)


        <# --------------------------------------------------------------------
            If specified, add RDS Licensing Server
        #> 
        if ($RDLicensing)
        {
            # iterate each entry and add
            foreach ($l in $RDLicensing)
            {
                # create execution name for the resource
                $executionName = "Licensing_$($l -replace '[-().:\s]', '_')"

                # evaluate the FQDN of the named server
                $l = [System.Net.Dns]::GetHostByName("$l").HostName

                # create DSC Resource for RD Connection Broker
                xRDServer $executionName
                {
                    ConnectionBroker = $localHost
                    Server           = $l
                    Role             = 'RDS-Licensing'
                    DependsOn        = '[xWindowsFeature]AddRdsConnectionBroker'
                } #end xRDServer
            } #end foreach
        } #end if ($RDLicensing)


        <# --------------------------------------------------------------------
            If specified, add RDS Web Access servers
        #> 
        if ($RDWebAccess)
        {
            # iterate each entry and add
            foreach ($w in $RDWebAccess)
            {
                # create execution name for the resource
                $executionName = "WebAccess_$($w -replace '[-().:\s]', '_')"

                # evaluate the FQDN of the named server
                $w = [System.Net.Dns]::GetHostByName("$w").HostName

                # create DSC Resource for RD Connection Broker
                xRDServer $executionName
                {
                    ConnectionBroker = $localHost
                    Server           = $w
                    Role             = 'RDS-Web-Access'
                    DependsOn        = '[xWindowsFeature]AddRdsConnectionBroker'
                } #end xRDServer
            } #end foreach
        } #end if ($RDWebAccess)


        <# --------------------------------------------------------------------
            If specified, add RDS Session Host
        #> 
        if ($RDSessionHost)
        {
            # iterate each entry and add
            foreach ($s in $RDSessionHost)
            {
                # create execution name for the resource
                $executionName = "SessionHost_$($s -replace '[-().:\s]', '_')"

                # evaluate the FQDN of the named server
                $s = [System.Net.Dns]::GetHostByName("$s").HostName

                # create DSC Resource for RD Connection Broker
                xRDServer $executionName
                {
                    ConnectionBroker = $localHost
                    Server           = $s
                    Role             = 'RDS-RD-Server'
                    DependsOn        = '[xWindowsFeature]AddRdsConnectionBroker'
                } #end xRDServer
            } #end foreach
        } #end if ($RDSessionHost)
    }
} #end configuration