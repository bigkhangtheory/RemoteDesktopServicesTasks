<#
    .SYNOPSIS
        The RdGatewayConnectionAuthorizationPolicies DSC configuration is used to manage Remote Desktop connection authorization policies (RD CAP) to allow users access to a RD Gateway server.

    .PARAMETER DomainDN
        Distinguished Name (DN) of the domain.

    .PARAMETER Policies
        Specifies a list of RD Gateway connection authorization policies (RD CAP) to create on the RD Gateway server.
#>
#Requires -Module xPSDesiredStateConfiguration


configuration RdGatewayConnectionAuthorizationPolicies
{
    param
    (
        [Parameter(Mandatory)]
        [ValidatePattern('^((DC=[^,]+,?)+)$')]
        [System.String]
        $DomainDN,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable[]]
        $Policies
    )

    <#
        .NOTES
            Import required modules
    #>
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xPSDesiredStateConfiguration


    <#
        Convert DN to Fqdn
    #>
    $pattern = '(?i)DC=(?<name>\w+){1,}?\b'
    $myDomainName = ([RegEx]::Matches($DomainDN, $pattern) | ForEach-Object { $_.groups['name'] }) -join '.'


    <#
        .NOTES
            Installed prerequisite resources for an RD Gateway server
    #>
    WindowsFeature AddRdsGateway
    {
        Name   = 'RDS-Gateway'
        Ensure = 'Present'
    }

    WindowsFeature AddRsatRdsGateway
    {
        Name      = 'RSAT-RDS-Gateway'
        Ensure    = 'Present'
        DependsOn = '[WindowsFeature]AddRdsGateway'
    }

    # set variable to maintain resource dependencies
    $dependsOnAddRsatRdsGateway = '[WindowsFeature]AddRsatRdsGateway'


    <#
        .NOTES
            Create DSC xScript resource to create the RD CAPs
    #>
    if ($PSBoundParameters.ContainsKey('Policies'))
    {
        # create index to meter the policy evaluation order
        $index = 1

        foreach ($p in $Policies)
        {
            # create hashtable to store properties of the resource with some defaults
            $params = @{
                Status                = 1
                EvaluationOrder       = $index
                AuthMethod            = 1
                AllowOnlySDRTSServers = 0
                IdleTimeout           = 0
                SessionTimeout        = 0
                SessionTimeoutAction  = 0
                UserGroups            = @()
                ComputerGroups        = @()
            }

            # remove case sensitivity of ordered Dictionary or Hashtables
            $p = @{} + $p

            # the property 'Name' must be specified, otherwise fail
            if (-not $p.ContainsKey('Name'))
            {
                throw 'ERROR: The property Name is not defined.'
            }
            else
            {
                $params.Name = $p.Name
            }

            # the property 'UserGroups' must be specified, otherwise fail
            if (-not $p.ContainsKey('UserGroups'))
            {
                throw 'ERROR: The property UserGroups must be defined.'
            }
            else
            {
                # enumerate all User Groups and format the principal name
                foreach ($u in $p.UserGroups)
                {
                    $userGroup = '{0}@{1}' -f $u, $myDomainName.Split('.')[0].ToUpper()

                    $params.UserGroups += $userGroup
                }
            }

            # if '' not specified, set default value, otherwise map the valid value
            if ($p.ContainsKey('Status'))
            {
                $params.Status = switch ($p.Status)
                {
                    'Disabled' { 0 }
                    'Enabled' { 1 }
                    Default { 1 }
                }
            }

            # if 'EvaluationOrder' is specified, set the value to params hashtable
            if ($p.ContainsKey('EvaluationOrder'))
            {
                $params.EvaluationOrder = $p.EvaluationOrder
            }

            # if 'AuthMethod' not specified, set default value, othwerise map the valid value
            if ($p.ContainsKey('AuthMethod'))
            {
                # switch state mapping valid strings to values
                $params.AuthMethod = switch ($p.AuthMethod)
                {
                    'None' { 0 }
                    'Password' { 1 }
                    'SmartCard' { 2 }
                    'Both' { 3 }
                    Default { 1 }
                }
            }

            # if 'IdleTimeout' not specified, set default value
            if ($p.ContainsKey('IdleTimeout'))
            {
                # the valid range is 0 - 1440
                if (-not ( ($p.IdleTimeout -ge 0) -and ($p.IdleTimeout -le 1440) ) )
                {
                    throw 'ERROR: The property IdleTiemout must be within the value range of 0 ... 1440.'
                }

                $params.IdleTimeout = $p.IdleTimeout
            }

            # if 'SessionTimeout' not specified, set default value
            if (-not $p.ContainsKey('SessionTimeout'))
            {
                # the valid range is 0 - 32766
                if (-not ( ($p.SessionTimeout -ge 0) -and ($p.SessionTimeout -le 32766) ) )
                {
                    throw 'ERROR: The property SessionTimeout must be within the value range of 0 ... 32766.'
                }

                $params.SessionTimeout = $p.SessionTimeout
            }

            # if the property 'SessionTimeout' is greater than 0, evaluate the 'SessionTimeoutAction'
            if ($params.SessionTimeout -gt 0)
            {
                # if 'SessionTimeoutAction' not specified, set defaults
                if ($p.ContainsKey('SessionTimeoutAction'))
                {
                    $params.SessionTimeoutAction = switch ($p.SessionTimeoutAction)
                    {
                        'Disconnect' { 0 }
                        'Reauthorize' { 1 }
                        Default { 0 }
                    }
                }
            }

            # set configuration parameter values
            $name = $params.Name
            $status = $params.Status
            $evaluationOrder = $params.EvaluationOrder
            $authMethod = $params.AuthMethod
            $allowOnlySDRTSServers = $params.AllowOnlySDRTSServers
            $idleTimeout = $params.IdleTimeout
            $sessionTimeout = $params.SessionTimeout
            $sessionTimeoutAction = $params.SessionTimeoutAction
            $userGroups = $params.UserGroups


            <#
                .NOTES
                    Create DSC xScript resource for the RD Gateway RD CAP
            #>

            # create execution name for the resource
            $executionName = "RD_CAP_$("$($p.Name)_$($p.Status)_$($p.UserGroups)" -replace '[-().:\s]', '_')"


            $output = @"

            Create DSC xScript resource:

            xScript $executionName
            {
                Name                  = $name
                Status                = $status
                EvaluationOrder       = $evaluationOrder
                AuthMethod            = $authMethod
                AllowOnlySDRTSServers = $allowOnlySDRTSServers
                IdleTimeout           = $idleTimeout
                SessionTimeout        = $sessionTimeout
                SessionTimeoutAction  = $sessionTimeoutAction
                UserGroups            = $userGroups

            }
"@

            Write-Host $output -ForegroundColor Yellow


            xScript "$executionName"
            {
                TestScript = {

                    # import the RemoteDesktopServices PS Module
                    Import-Module -Name RemoteDesktopServices -ErrorAction SilentlyContinue

                    # stage desired state flag
                    [System.Boolean]$inDesiredState = $true

                    # set verbose output during testing
                    Write-Verbose "Test RD CAP '$using:name' -> expect Status: '$using:status', EvaluationOrder: '$using:evaluationOrder', AuthMethod: '$using:authMethod', IdleTimeout: '$using:idleTimeout', SessionTimeout: '$using:sessionTimeout', SessionTimeoutAction: '$using:sessionTimeoutAction', UserGroups: '$using:UserGroups'"


                    # format the RD CAP path
                    $path = 'RDS:\GatewayServer\CAP\{0}' -f $using:name

                    # query for existing RD CAP
                    $cap = Get-Item -Path $path -ErrorAction SilentlyContinue

                    if ($null -ne $cap)
                    {
                        Write-Verbose -Message "RD CAP $($cap.Name) is found."

                        # the item name must match
                        if ( $cap.Name -eq $using:name )
                        {
                            # query all current values
                            $capStatus = Get-Item -Path "$path\Status"
                            $capEvaluationOrder = Get-Item -Path "$path\EvaluationOrder"
                            $capAuthMethod = Get-Item -Path "$path\AuthMethod"
                            $capAllowOnlySDRTSServers = Get-Item -Path "$path\AllowOnlySDRTSServers"
                            $capIdleTimeout = Get-Item -Path "$path\IdleTimeout"
                            $capSessionTimeout = Get-Item -Path "$path\SessionTimeout"
                            $capSessionTimeoutAction = Get-Item -Path "$path\SessionTimeoutAction"
                            $capUserGroups = Get-Item -Path "$path\UserGroups" | Get-ChildItem | % Name

                            # evaluate each state of the RD CAP object
                            if (-not ($using:status -eq $capStatus) )
                            {
                                Write-Verbose -Message "RD CAP 'Status' not in desired state. Expected -> Status: '$using:status', Actual -> Status: '$capStatus'"
                                $inDesiredState = $false
                            }

                            if (-not ($using:evaluationOrder -eq $capEvaluationOrder) )
                            {
                                Write-Verbose -Message "RD CAP 'EvaluationOrder' not in desired state. Expected -> Status: '$using:evaluationOrder', Actual -> Status: '$capEvaluationOrder'"
                                $inDesiredState = $false
                            }


                            if (-not ($using:authMethod -eq $capAuthMethod) )
                            {
                                Write-Verbose -Message "RD CAP 'AuthMethod' not in desired state. Expected -> Status: '$using:authMethod', Actual -> Status: '$capAuthMethod'"
                                $inDesiredState = $false
                            }

                            if (-not ($using:allowOnlySDRTSServers -eq $capAllowOnlySDRTSServers) )
                            {
                                Write-Verbose -Message "RD CAP 'AllowOnlySDRTSServers' not in desired state. Expected -> Status: '$using:allowOnlySDRTSServers', Actual -> Status: '$capAllowOnlySDRTSServers'"
                                $inDesiredState = $false
                            }

                            if (-not ($using:idleTimeout -eq $capIdleTimeout) )
                            {
                                Write-Verbose -Message "RD CAP 'IdleTimeout' not in desired state. Expected -> Status: '$using:idleTimeout', Actual -> Status: '$capIdleTimeout'"
                                $inDesiredState = $false
                            }

                            if (-not ($using:sessionTimeout -eq $capSessionTimeout) )
                            {
                                Write-Verbose -Message "RD CAP 'SessionTimeout' not in desired state. Expected -> Status: '$using:sessionTimeout ', Actual -> Status: '$capSessionTimeout'"
                                $inDesiredState = $false
                            }

                            if (-not ($using:sessionTimeoutAction -eq $capSessionTimeoutAction) )
                            {
                                Write-Verbose -Message "RD CAP 'SessionTimeoutAction' not in desired state. Expected -> Status: '$using:sessionTimeoutAction', Actual -> Status: '$capSessionTimeoutAction'"
                                $inDesiredState = $false
                            }

                            if ( $null -ne (Compare-Object -ReferenceObject $using:userGroups -DifferenceObject $capUserGroups ) )
                            {
                                Write-Verbose -Message "RD CAP 'UserGroups' not in desired state. Expected -> Status: '$using:userGroups', Actual -> Status: '$capUserGroups'"
                                $inDesiredState = $false
                            }
                        } #end if
                    }
                    else
                    {
                        Write-Verbose -Message "RD CAP $($cap.Name) is not found."
                        $inDesiredState = $false
                    } #end if

                    return $inDesiredState
                } #end TestScript

                SetScript  = {

                    # import the RemoteDesktopServices PS Module
                    Import-Module -Name RemoteDesktopServices -ErrorAction SilentlyContinue

                    $parentPath = 'RDS:\GatewayServer\CAP'
                    # format the RD CAP path
                    $path = '{0}\{1}' -f $parentPath, $using:name

                    # query for existing RD CAP
                    $cap = Get-Item -Path $path -ErrorAction SilentlyContinue

                    if ($null -ne $cap)
                    {

                    }
                    else
                    {
                        # at this point the RD CAP is not found and will be created

                        # splat parameters in hashtable
                        $Splatting = @{
                            Path                  = $path
                            Name                  = $using:name
                            Status                = $using:status
                            EvaluationOrder       = $using:evaluationOrder
                            AuthMethod            = $using:authMethod
                            AllowOnlySDRTSServers = $using:allowOnlySDRTSServers
                            IdleTimeout           = $using:idleTimeout
                            SessionTimeout        = $using:sessionTimeout
                            SessionTimeoutAction  = $using:sessionTimeoutAction
                            UserGroups            = $using:userGroups
                        }
                        (New-Item @Splatting)
                    } #end if
                } #end SetScript

                GetScript  = {
                    return @{ Result = 'N/A' }
                } #end GetScript

            } #end xScript
        } #end foreach
    } #end if
} #end configuration