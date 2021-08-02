<#
    .DESCRIPTION
        This DSC configuration creates and configures an RD Gateway server.
#>
#requires -Module xRemoteDesktopSessionHost

configuration RdGatewayRole
{
    param 
    (
        [Parameter(Mandatory)]
        [System.String]
        $ConnectionBrokerFqdn,

        [Parameter(Mandatory)]
        [System.String]
        $GatewayExternalFqdn,

        [Parameter()]
        [System.String]
        $GatewayMode = 'Automatic',

        [Parameter()]
        [System.String]
        $LogonMethod,
        
        [Parameter()]
        [System.Boolean]
        $UseCachedCredentials,

        [Parameter()]
        [System.Boolean]
        $BypassLocal
    )

    Import-DscResource -Module PSDesiredStateConfiguration
    Import-DscResource -Module xRemoteDesktopSessionHost

    # retrieve hostname of this node
    $localhost = '{0}.mapcom.local]' -f $env:ComputerName

    # if the Connect Broker is not specifed, then assume this node
    WindowsFeature AddRdGateway
    {
        Name   = 'RDS-Gateway'
        Ensure = 'Present'
    }
    WindowsFeature AddRsatRdsGateway
    {
        Name   = 'RSAT-RDS-Gateway'
        Ensure = 'Present'
    }

}