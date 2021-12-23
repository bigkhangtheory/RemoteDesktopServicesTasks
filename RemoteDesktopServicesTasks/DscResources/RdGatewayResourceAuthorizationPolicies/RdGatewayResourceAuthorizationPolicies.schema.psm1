<#
    .SYNOPSIS
        The RdGatewayResourceAuthorizationPolicies DSC configuration manages RD Gateway resource authorization policy (RD RAP) to allow users to connect to remote computers on the network by using RD Gateway.

    .PARAMETER DomainDN
        Distinguished Name (DN) of the domain.

    .PARAMETER Policies
        Specifies a list of RD Gateway connection authorization policies (RD RAP) to create on the RD Gateway server.
#>
#Requires -Module xPSDesiredStateConfiguration


configuration RdGatewayResourceAuthorizationPolicies
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
            Create DSC xScript resource to create the RD RAPs
    #>
    if ($PSBoundParameters.ContainsKey('Policies'))
    {

        foreach ($p in $Policies)
        {
            # create hashtable to store properties of the resource with some defaults
            $params = @{
                Status            = 1
                Description       = ''
                PortNumbers       = '3389'
                ComputerGroupType = 2
                ComputerGroup     = 'NULL'
                UserGroups        = @()
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

            # if 'Description' is specified, set the value to params hashtable
            if ($p.ContainsKey('Description'))
            {
                $params.Description = $p.Description
            }

            # if 'ComputerGroupType' not specified, set default value, othwerise map the valid value
            if ($p.ContainsKey('ComputerGroupType'))
            {
                # switch state mapping valid strings to values
                $params.ComputerGroupType = switch ($p.ComputerGroupType)
                {
                    'GatewayManaged' { 0 }
                    'DomainManaged' { 1 }
                    'Any' { 2 }
                    Default { 2 }
                }
            }

            # if 'ComputerGroupType' is either 'GatewayManaged' or 'DomainManaged', the property 'ComputerGroup' must be specified
            if ( ($params.ComputerGroupType -eq 0) -or ($params.ComputerGroupType -eq 1) )
            {
                # the valid range is 0 - 1440
                if (-not $p.ContainsKey('ComputerGroup') )
                {
                    throw 'ERROR: The property ComputerGroup must be specified.'
                }

                $params.ComputerGroup = $p.ComputerGroup
            }


            # set configuration parameter values
            $name = $params.Name
            $status = $params.Status
            $description = $params.Description
            $portNumbers = $params.PortNumbers
            $computerGroupType = $params.ComputerGroupType
            $computerGroup = $params.ComputerGroup
            $userGroups = $params.UserGroups


            <#
                .NOTES
                    Create DSC xScript resource for the RD Gateway RD RAP
            #>

            # create execution name for the resource
            $executionName = "RD_RAP_$("$($p.Name)_$($p.Status)_$($p.UserGroups)" -replace '[-().:\s]', '_')"


            $output = @"

            Create DSC xScript resource:

            xScript $executionName
            {
                Name                  = $name
                Status                = $status
                Description           = $description
                PortNumbers           = $portNumbers
                ComputerGroupType     = $computerGroupType
                ComputerGroup         = $computerGroup
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
                    Write-Verbose "Test RD RAP '$using:name' -> expect Status: '$using:status', Description: '$using:description', PortNumbers: '$using:portNumbers', ComputerGrouptType: '$using:computerGroupType', ComputerGroup: '$using:computerGroup', UserGroups: '$using:UserGroups'"

                    # format the RD RAP path
                    $path = 'RDS:\GatewayServer\RAP\{0}' -f $using:name

                    # query for existing RD RAP
                    $rap = Get-Item -Path $path -ErrorAction SilentlyContinue

                    if ($null -ne $rap)
                    {
                        Write-Verbose -Message "RD RAP $($rap.Name) is found."

                        # the item name must match
                        if ( $rap.Name -eq $using:name )
                        {
                            # query all current values
                            $rapStatus = Get-Item -Path "$path\Status"
                            $rapDescription = Get-Item -Path "$path\Description"
                            $rapPortNumbers = Get-Item -Path "$path\PortNumbers"
                            $rapComputerGroupType = Get-Item -Path "$path\ComputerGroupType"
                            $rapComputerGroup = Get-Item -Path "$path\ComputerGroup"
                            $rapUserGroups = Get-Item -Path "$path\UserGroups" | Get-ChildItem | % Name

                            # evaluate each state of the RD RAP object
                            if (-not ($using:status -eq $rapStatus) )
                            {
                                Write-Verbose -Message "RD RAP 'Status' not in desired state. Expected -> Status: '$using:status', Actual -> Status: '$rapStatus'"
                                $inDesiredState = $false
                            }

                            if (-not ($using:description -eq $rapDescription) )
                            {
                                Write-Verbose -Message "RD RAP 'Description' not in desired state. Expected -> Status: '$using:description', Actual -> Status: '$rapDescription'"
                                $inDesiredState = $false
                            }


                            if (-not ($using:portNumbers -eq $rapPortNumbers) )
                            {
                                Write-Verbose -Message "RD RAP 'PortNumbers' not in desired state. Expected -> Status: '$using:portNumbers', Actual -> Status: '$rapPortNumbers'"
                                $inDesiredState = $false
                            }

                            if (-not ($using:computerGroupType -eq $rapComputerGroupType) )
                            {
                                Write-Verbose -Message "RD RAP 'ComputerGroupType' not in desired state. Expected -> Status: '$using:computerGroupType', Actual -> Status: '$rapComputerGroupType'"
                                $inDesiredState = $false
                            }

                            if (-not ($using:computerGroup -eq $rapComputerGroup) )
                            {
                                Write-Verbose -Message "RD RAP 'ComputerGroup' not in desired state. Expected -> Status: '$using:computerGroup', Actual -> Status: '$rapComputerGroup'"
                                $inDesiredState = $false
                            }

                            if ( $null -ne (Compare-Object -ReferenceObject $using:userGroups -DifferenceObject $rapUserGroups ) )
                            {
                                Write-Verbose -Message "RD RAP 'UserGroups' not in desired state. Expected -> Status: '$using:userGroups', Actual -> Status: '$rapUserGroups'"
                                $inDesiredState = $false
                            }
                        } #end if
                    }
                    else
                    {
                        Write-Verbose -Message "RD RAP $($rap.Name) is not found."
                        $inDesiredState = $false
                    } #end if

                    return $inDesiredState
                } #end TestScript

                SetScript  = {

                    # import the RemoteDesktopServices PS Module
                    Import-Module -Name RemoteDesktopServices -ErrorAction SilentlyContinue

                    $parentPath = 'RDS:\GatewayServer\RAP'
                    # format the RD RAP path
                    $path = '{0}\{1}' -f $parentPath, $using:name

                    # query for existing RD RAP
                    $rap = Get-Item -Path $path -ErrorAction SilentlyContinue

                    if ($null -ne $rap)
                    {
                        # query all current values
                        $rapStatus = Get-Item -Path "$path\Status"
                        $rapDescription = Get-Item -Path "$path\Description"
                        $rapPortNumbers = Get-Item -Path "$path\PortNumbers"
                        $rapComputerGroupType = Get-Item -Path "$path\ComputerGroupType"
                        $rapComputerGroup = Get-Item -Path "$path\ComputerGroup"
                        $rapUserGroups = Get-Item -Path "$path\UserGroups" | Get-ChildItem | % Name

                        # evaluate each state of the RD RAP object
                        if (-not ($using:status -eq $rapStatus) )
                        {
                            $rapStatus | Set-Item -Value $using:status
                        }

                        if (-not ($using:description -eq $rapDescription) )
                        {
                            $rapDescription | Set-Item -Value $using:description
                        }

                        if (-not ($using:portNumbers -eq $rapPortNumbers) )
                        {
                            $rapPortNumbers | Set-Item -Value $using:portNumbers
                        }

                        if (-not ($using:computerGroupType -eq $rapComputerGroupType) )
                        {
                            $rapComputerGroupType | Set-Item -Value $using:computerGroupType
                        }

                        if (-not ($using:computerGroup -eq $rapComputerGroup) )
                        {
                            $rapComputerGroup | Set-Item -Value $using:computerGroup
                        }

                        if ( $null -ne (Compare-Object -ReferenceObject $using:userGroups -DifferenceObject $rapUserGroups ) )
                        {
                            # if the UserGroups do not match, destroy the existing item and re-create
                            $rap | Remove-Item -Recurse -Force -ErrorAction 'SilentlyContinue'

                            # splat parameters in hashtable
                            $Splatting = @{
                                Path              = $parentPath
                                Name              = $using:name
                                Status            = $using:status
                                Description       = $using:description
                                PortNumbers       = $using:portNumbers
                                ComputerGroupType = $using:computerGroupType
                                ComputerGroup     = $using:computerGroup
                                UserGroups        = $using:userGroups
                            }
                            New-Item @Splatting
                        }
                    }
                    else
                    {
                        # at this point the RD RAP is not found and will be created

                        # splat parameters in hashtable
                        $Splatting = @{
                            Path              = $parentPath
                            Name              = $using:name
                            Status            = $using:status
                            Description       = $using:description
                            PortNumbers       = $using:portNumbers
                            ComputerGroupType = $using:computerGroupType
                            ComputerGroup     = $using:computerGroup
                            UserGroups        = $using:userGroups

                        }
                        New-Item @Splatting
                    } #end if
                } #end SetScript

                GetScript  = {

                    # import the RemoteDesktopServices PS Module
                    Import-Module -Name RemoteDesktopServices -ErrorAction SilentlyContinue

                    $parentPath = 'RDS:\GatewayServer\RAP'
                    # format the RD RAP path
                    $path = '{0}\{1}' -f $parentPath, $using:name

                    # query for existing RD RAP
                    $rap = Get-Item -Path $path -ErrorAction SilentlyContinue

                    return @{ Result = $rap }
                } #end GetScript

                # this resource depends on installation of RD Gateway
                DependsOn  = $dependsOnAddRsatRdsGateway
            } #end xScript
        } #end foreach
    } #end if
} #end configuration