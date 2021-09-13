<#
    .DESCRIPTION
        This DSC configuration installs the Remote Desktop web client lets users access Remote Desktop infrastructure through a compatible web browser.
#>
#Requires -Module PSModulesDsc
#Requires -Module xPSDesiredStateConfiguration

configuration RDWebClient
{
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Version,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ConnectionBrokerCertificate,

        [Parameter()]
        [System.String]
        $SuppressTelemetry = $false,

        [Parameter()]
        [ValidateSet('Production', 'Test')]
        $PublishedAs,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        $Ensure
    )

    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName PSModulesDsc

    
    <#
        Install Windows feature requirements
    #>
    xWindowsFeature AddRdsWebAccess
    {
        Name   = 'RDS-Web-Access'
        Ensure = 'Present'
    }

    <#
        Install PowerShell module requirements
    #>
    PowershellModule InstallPowerShellGet
    {
        Name       = 'PowerShellGet'
        Repository = 'PSGallery'
        Ensure     = 'Present'
    }
    PowershellModule InstallRdWebClientManagement
    {
        Name       = 'RDWebClientManagement'
        Repository = 'PSGallery'
        Ensure     = 'Present'
        DependsOn  = '[PowershellModule]InstallPowerShellGet'
    }

    <#
        Create DSC script resource for RD Web Client package resource
    #>
    xScript RDWebClientPackage
    {
        <#
            Retrieve the current state of RD Web Client package resource
        #>
        GetScript  = {
            Write-Verbose -Message 'Returning the RD Web Client package resource.'

            return @{
                Result = (Get-RDWebClientPackage)
            }
        } #end GetScript

        <#
            Set the state of the RD Web Client package resource
        #>
        SetScript  = {
            Write-Verbose -Message "Installing the Remote Desktop Web Client package version $Using:Version."

            try
            {
                Install-RDWebClientPackage -RequiredVersion $Using:Version
            }
            catch
            {
                throw "$($_.Exception.Message)"
            }
        } #end SetScript

        <#
            Validate whether or not the RD Web Client package resource is in the desired state
        #>
        TestScript = {
            Write-Verbose -Message "Verifying RD Web Client package is version $Using:Version."

            if ((Get-RDWebClientPackage | Where-Object -Property 'version' -EQ -Value $Using:Version))
            {
                return $true
            }
            else
            {
                return $false
            }  
        } #end TestScript
    } #end RDWebClientPackage


    <#
        Create DSC script resource for Connection Broker Certificate
    #>
    if ($ConnectionBrokerCertificate)
    {
        xScript RDWebClientBrokerCert
        {
            <#
                Retrieve the current state of the Connection Broker Certificate
            #>
            GetScript  = {
                Write-Verbose -Message 'Returning the broker certificate used by the Remote Desktop web client.'

                return @{
                    Result = (Get-RDWebClientBrokerCert)
                }
            } #end GetScript

            <#
                Set the state of the RD Web Client package resource
            #>
            SetScript  = {
                Write-Verbose -Message 'Importing the broker certificate for Remote Desktop Web Client package.'

                try
                {
                    Import-RDWebClientBrokerCert -Path $Using:Path -Verbose
                }
                catch
                {
                    throw "$($_.Exception.Message)"
                }
            } #end SetScript

            <#
                Validate whether or not the RD Web Client package resource is in the desired state
            #>
            TestScript = {
                Write-Verbose -Message 'Verifying broker certificate for Remote Desktop Web Client package'

                $myCert = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Certificate2

                try
                {
                    $myCert.Import((Get-Item -Path $ConnectionBrokerCertificate))
                }
                catch 
                {
                    throw "$($_.Exception.Message)"
                }

                if ( (Get-RDWebClientBrokerCert | Select-Object -ExpandProperty Thumbprint) -eq $myCert.Thumbprint)
                {
                    return $true
                }
                else
                {
                    return $false
                } 

            } #end TestScript
        } #end RDWebClientBrokerCert
    } #end if


    <#
        Create DSC resource for publishing the RD Web Client
    #>
    if ($Ensure -eq 'Present')
    {
        xScript PublishRDWebClientPackage
        {
            <#
                Retrieve the RD Web Client package
            #>
            GetScript  = {
                Write-Verbose -Message 'Returning the RD Web Client package resource.'

                return @{
                    Result = (Get-RDWebClientPackage)
                }
            } #end GetScript

            <#
                Set the publishing type of the RD Web Client package
            #>
            SetScript  = {
                Write-Verbose -Message 'Publishing the RD Web Client package.'

                try
                {
                    Publish-RDWebClientPackage -Type $Using:PublishedAs -Latest
                }
                catch
                {
                    throw "$($_.Exception.Message)"
                }
            } #end SetScript

            <#
                Test the publishing status of the RD Web Client package
            #>
            TestScript = {
                Write-Verbose -Message "Verifying the RD Web Client package is published as $Using:PublishedAs"

                if ((Get-RDWebClientPackage | Where-Object -Property publishedAs -EQ -Value $Using:PublishedAs))
                {
                    return $true
                }
                else
                {
                    return $false
                }
            } #end TestScript
        }
    }
}