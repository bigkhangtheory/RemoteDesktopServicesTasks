<#
    .SYNOPSIS
        The RdGatewayManagedComputerGroups DSC configuration is used to create a local collection of remote computers for the RD Gateway server to manage RDP connections

    .PARAMETER DomainDN
        Distinguished Name (DN) of the domain.

    .PARAMETER ComputerGroups
        Specifies a list of RD Gateway managed computer groups to create.
#>
#Requires -Module xPSDesiredStateConfiguration


configuration RdGatewayManagedComputerGroups
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
        $ComputerGroups
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
            Create DSC xScript resource to create the RD GatewayManagedComputerGroupss
    #>
    if ($PSBoundParameters.ContainsKey('ComputerGroups'))
    {

        foreach ($g in $ComputerGroups)
        {
            # create hashtable to store properties of the resource with some defaults
            $params = @{
                Description = ''
                Computers   = @()
            }

            # remove case sensitivity of ordered Dictionary or Hashtables
            $g = @{} + $g

            # the property 'Name' must be specified, otherwise fail
            if (-not $g.ContainsKey('Name'))
            {
                throw 'ERROR: The property Name is not defined.'
            }
            else
            {
                $params.Name = $g.Name
            }

            # the property 'Computers' must be specified, otherwise fail
            if (-not $g.ContainsKey('Computers'))
            {
                throw 'ERROR: The property Computers must be defined.'
            }
            else
            {
                # enumerate all User Groups and format the principal name
                foreach ($c in $g.Computers)
                {
                    $computerNetBiosName = $c

                    $computerFqdn = '{0}.{1}' -f $c, $myDomainName

                    $params.Computers += $computerNetBiosName, $computerFqdn
                }
            }

            # if 'Description' is specified, set the value to params hashtable
            if ($g.ContainsKey('Description'))
            {
                $params.Description = $g.Description
            }


            # set configuration parameter values
            $name = $params.Name
            $description = $params.Description
            $computers = $params.Computers


            <#
                .NOTES
                    Create DSC xScript resource for the RD Gateway RD GatewayManagedComputerGroups
            #>

            # create execution name for the resource
            $executionName = "RD_GatewayManagedComputerGroups_$("$($g.Name)_$($g.Computers)" -replace '[-().:\s]', '_')"


            $output = @"

            Create DSC xScript resource:

            xScript $executionName
            {
                Name                  = $name
                Description           = $description
                Computers             = $computers
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
                    Write-Verbose "Test RD Gateway Managed Group '$using:name' -> Description: '$using:description', Computers: '$using:computers'"

                    # format the RD GatewayManagedComputerGroups path
                    $path = 'RDS:\GatewayServer\GatewayManagedComputerGroups\{0}' -f $using:name

                    # query for existing RD GatewayManagedComputerGroups
                    $managedComputerGroup = Get-Item -Path $path -ErrorAction SilentlyContinue

                    if ($null -ne $managedComputerGroup)
                    {
                        Write-Verbose -Message "RD GatewayManagedComputerGroups $($managedComputerGroup.Name) is found."

                        # the item name must match
                        if ( $managedComputerGroup.Name -eq $using:name )
                        {
                            # query all current values
                            $managedComputerGroupDescription = Get-Item -Path "$path\Description"
                            $managedComputerGroupComputers = Get-Item -Path "$path\Computers" | Get-ChildItem | % Name

                            if (-not ($using:description -eq $managedComputerGroupDescription) )
                            {
                                Write-Verbose -Message "RD GatewayManagedComputerGroups 'Description' not in desired state. Expected -> Status: '$using:description', Actual -> Status: '$managedComputerGroupDescription'"
                                $inDesiredState = $false
                            }

                            if ( $null -ne (Compare-Object -ReferenceObject $using:computers -DifferenceObject $managedComputerGroupComputers ) )
                            {
                                Write-Verbose -Message "RD GatewayManagedComputerGroups 'Computers' not in desired state. Expected -> Status: '$using:computers', Actual -> Status: '$managedComputerGroupComputers'"
                                $inDesiredState = $false
                            }
                        } #end if
                    }
                    else
                    {
                        Write-Verbose -Message "RD GatewayManagedComputerGroups $($managedComputerGroup.Name) is not found."
                        $inDesiredState = $false
                    } #end if

                    return $inDesiredState
                } #end TestScript

                SetScript  = {

                    # import the RemoteDesktopServices PS Module
                    Import-Module -Name RemoteDesktopServices -ErrorAction SilentlyContinue

                    $parentPath = 'RDS:\GatewayServer\GatewayManagedComputerGroups'
                    # format the RD GatewayManagedComputerGroups path
                    $path = '{0}\{1}' -f $parentPath, $using:name

                    # query for existing RD GatewayManagedComputerGroups
                    $managedComputerGroup = Get-Item -Path $path -ErrorAction SilentlyContinue

                    if ($null -ne $managedComputerGroup)
                    {
                        # query all current values
                        $managedComputerGroupDescription = Get-Item -Path "$path\Description"
                        $managedComputerGroupComputers = Get-Item -Path "$path\Computers" | Get-ChildItem | % Name

                        if (-not ($using:description -eq $managedComputerGroupDescription) )
                        {
                            $managedComputerGroupDescription | Set-Item -Value $using:description
                        }

                        if ( $null -ne (Compare-Object -ReferenceObject $using:computers -DifferenceObject $managedComputerGroupComputers ) )
                        {
                            # if the Computers do not match, destroy the existing item and re-create
                            $managedComputerGroup | Remove-Item -Recurse -Force -ErrorAction 'SilentlyContinue'

                            # splat parameters in hashtable
                            $Splatting = @{
                                Path        = $parentPath
                                Name        = $using:name
                                Description = $using:description
                                Computers   = $using:computers
                                Force       = $true
                            }
                            New-Item @Splatting
                        }
                    }
                    else
                    {
                        # at this point the RD GatewayManagedComputerGroups is not found and will be created

                        # splat parameters in hashtable
                        $Splatting = @{
                            Path        = $parentPath
                            Name        = $using:name
                            Description = $using:description
                            Computers   = $using:computers
                            Force       = $true

                        }
                        New-Item @Splatting
                    } #end if
                } #end SetScript

                GetScript  = {

                    # import the RemoteDesktopServices PS Module
                    Import-Module -Name RemoteDesktopServices -ErrorAction SilentlyContinue

                    $parentPath = 'RDS:\GatewayServer\GatewayManagedComputerGroups'
                    # format the RD GatewayManagedComputerGroups path
                    $path = '{0}\{1}' -f $parentPath, $using:name

                    # query for existing RD GatewayManagedComputerGroups
                    $managedComputerGroup = Get-Item -Path $path -ErrorAction SilentlyContinue

                    # if the Managed Computer Group does not exist, return 'N/A'
                    if ($null -eq $managedComputerGroup)
                    {
                        $result = 'N/A'
                    }
                    else
                    {
                        $result = $managedComputerGroup
                    }

                    return @{ Result = $result }
                } #end GetScript

                # this resource depends on installation of RD Gateway
                DependsOn  = $dependsOnAddRsatRdsGateway
            } #end xScript
        } #end foreach
    } #end if
} #end configuration