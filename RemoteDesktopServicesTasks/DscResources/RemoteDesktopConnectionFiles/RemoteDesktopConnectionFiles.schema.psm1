configuration RemoteDesktopConnectionFiles
{
    param
    (
        [Parameter(Mandatory)]
        [ValidatePattern('^((DC=[^,]+,?)+)$')]
        [System.String]
        $DomainDN,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DestinationPath,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $PublishPath,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $GatewayAddress,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable[]]
        $Connections,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $PublishCredential
    )

    <#
        Import required modules
    #>
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xPSDesiredStateConfiguration


    <#
        Convert DN to Fqdn
    #>
    $pattern = '(?i)DC=(?<name>\w+){1,}?\b'
    $myDomainName = ([RegEx]::Matches($DomainDN, $pattern) | ForEach-Object { $_.groups['name'] }) -join '.'


    # if 'SourcePath' not specified, set default
    if (-not $PSBoundParameters.ContainsKey('DestinationPath'))
    {
        $DestinationPath = 'C:\RDP'
    }

    # create a File resource for the source path
    $executionName = "Folder_$("$($DestinationPath)" -replace '[-().:\\\s]', '_')"

    File $executionName
    {
        DestinationPath = $DestinationPath
        Type            = 'Directory'
        Force           = $true
        Ensure          = 'Present'
    }

    <#
        Create TextFile resources for each connection
    #>
    if ($PSBoundParameters.ContainsKey('Connections'))
    {
        # stage variable to hold resource dependencies
        $dependsOnRdpFile = New-Object -TypeName System.Collections.ArrayList

        foreach ($c in $Connections)
        {
            # remove case sensitivity for ordered Dictionary or Hashtable
            $c = @{} + $c


            # the property 'UserName' must be specified, otherwise fail
            if (-not $c.ContainsKey('UserName'))
            {
                throw 'ERROR: The property UserName is not defined.'
            }

            # format the user name
            $userName = '{0}@{1}' -f $c.UserName, $myDomainName


            # the property 'ComputerName' must be specified, otherwise fail
            if (-not $c.ContainsKey('ComputerName'))
            {
                throw 'ERROR: The property ComputerName is not defined.'
            }

            # format the computer name
            $computerName = '{0}.{1}' -f $c.ComputerName, $myDomainName


            # stage expiration flag
            [System.Boolean]$isExpired = $false

            # if the property 'ExpirationDate' is defined, evaluate
            if ($c.ContainsKey('ExpirationDate'))
            {
                $isExpired = [System.DateTime]$c.ExpirationDate -lt (Get-Date)
            }


            # if GatewayAddress is specified, enable it's usage
            if ($PSBoundParameters.ContainsKey('GatewayAddress'))
            {
                $useGatewayServer = '1'
            }
            else
            {
                $useGatewayServer = '0'
            }

            # format the file name
            $fileName = '{0}_{1}.rdp' -f $c.UserName.ToLower(), $c.ComputerName.ToUpper()

            # format the destination path
            $destPath = '{0}\{1}' -f $DestinationPath, $fileName


            # ensure the resource must be 'Present'
            [System.String]$ensure = 'Present'

            # if the entry is expired, the resource must be 'Absent'
            if ($isExpired)
            {
                $ensure = 'Absent'
            }


            # RDP file contents
            $contents = @"
screen mode id:i:2
use multimon:i:0
session bpp:i:32
winposstr:s:0,1,500,15,2335,1295
compression:i:1
keyboardhook:i:2
audiocapturemode:i:0
videoplaybackmode:i:1
connection type:i:7
networkautodetect:i:1
bandwidthautodetect:i:1
displayconnectionbar:i:1
enableworkspacereconnect:i:0
disable wallpaper:i:0
allow font smoothing:i:0
allow desktop composition:i:0
disable full window drag:i:1
disable menu anims:i:1
disable themes:i:0
disable cursor setting:i:0
bitmapcachepersistenable:i:1
audiomode:i:0
redirectprinters:i:0
redirectcomports:i:0
redirectsmartcards:i:0
redirectclipboard:i:1
redirectposdevices:i:0
autoreconnection enabled:i:1
authentication level:i:2
prompt for credentials:i:0
negotiate security layer:i:1
remoteapplicationmode:i:0
alternate shell:s:
shell working directory:s:
gatewayhostname:s:$GatewayAddress
gatewayusagemethod:i:1
gatewaycredentialssource:i:4
gatewayprofileusagemethod:i:$useGatewayServer
promptcredentialonce:i:1
gatewaybrokeringtype:i:0
use redirection server name:i:0
rdgiskdcproxy:i:0
kdcproxyname:s:
smart sizing:i:1
drivestoredirect:s:
username:s:$userName
full address:s:$computerName
"@


            # create execution name for the resource
            $executionName = "RDP_File_$("$($c.UserName)_$($c.ComputerName)" -replace '[-().:\s]', '_')"

            # create File resource
            File $executionName
            {
                DestinationPath = $destPath
                Type            = 'File'
                Contents        = $contents
                Force           = $true
                Ensure          = $ensure
            }

            # add resource dependency
            $dependsOnRdpFile = "[File]$executionName"

            <#
                If the PublishPath and Credential is specified, create Script resource to move the files over
            #>
            if ( ($PSBoundParameters.ContainsKey('PublishPath')) -and ($PSBoundParameters.ContainsKey('PublishCredential')) )
            {
                # create execution name for the resource
                $executionName = "Publish_$("$($executionName)" -replace '[-().:\s]', '_')"

                xScript $executionName
                {
                    TestScript           = {
                        return $false
                    }

                    SetScript            = {

                        # reset and remove all RDP files from the published path
                        Get-ChildItem -Path $using:PublishPath -Filter '*.rdp' -ErrorAction 'SilentlyContinue' | Remove-Item -Force -ErrorAction 'SilentlyContinue'

                        # retrieve all RDP files from the specified location
                        $rdpFiles = Get-ChildItem -Path $using:DestinationPath -ErrorAction 'SilentlyContinue'

                        # enumerate all RDP files and copy them to PublishingLocation
                        foreach ($r in $rdpFiles)
                        {
                            # splat Copy-Item parameters
                            $Splatting = @{
                                Path        = $r.FullName
                                Destination = $using:PublishPath
                                Force       = $true
                                PassThru    = $true
                                Credential  = $using:PublishCredential
                                ErrorAction = 'SilentlyContinue'
                            }
                            Copy-Item @Splatting
                        }


                    }

                    GetScript            = {
                        return @{ Result = 'N/A' }
                    }

                    PsDscRunAsCredential = $PublishCredential

                    DependsOn            = $dependsOnRdpFile
                } #end xScript
            } #end if
        } #end foreach
    }
} #end configuration