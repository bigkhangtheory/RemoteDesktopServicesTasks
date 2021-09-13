<#
    .DESCRIPTION
        This DSC configuration manages FormCache directories on a target node.
    .PARAMETER Path
        Specifies the file system path to the managed FormCache directory.
    .PARAMETER Users
        Specifies a list of user names to create folders for within the FormCache directory.
#>
#Requires -Module PSDesiredStateConfiguration
#Requires -Module DSCR_FileContent


configuration HUBA4FormCache
{
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Path,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $FileName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable[]]
        $IniSettings,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Users 
    )

    <#
        Import required modules
    #>
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName DSCR_FileContent


    <#
        Create DSC resource for each listed user
    #>
    foreach ($u in $Users)
    {
        # evaluate 'Ensure'
        $ensure = 'Present'

        if ($u[0] -in '-', '+')
        {
            if ($u[0] -eq '-')
            {
                $ensure = 'Absent'
            }
            $u = $u.Substring(1)
        }

        # append user to the FormCache root path
        $myUser = '{0}\{1}' -f $Path, $u

        # create execution name for the resource
        $executionName = "$($ensure)_$($myUser -replace '[-().:\\\s]', '_')"

        # create DSC resource for folders
        File "$executionName"
        {
            DestinationPath = $myUser
            Type            = 'Directory'
            Force           = $true
            Ensure          = $ensure
        } #end File
        
        # store configuration dependency
        $dependsOnDirectory = "[File]$executionName"
        
        
        # if ensure is Present, create DSC resource for PIAmtelco.ini
        if ($ensure -eq 'Present')
        {
            # append the Filename to the User directory path
            $myIni = '{0}\{1}' -f $myUser, $FileName

            # enumerate all INI settings
            foreach ($i in $IniSettings)
            {
                # remove case sensitivity of ordered Dictionary or Hashtables
                $i = @{ } + $i

                # set the path of the INI file
                $i.Path = $myIni

                # if not specified, set top level INI section
                if (-not $i.ContainsKey('Section'))
                {
                    $i.Section = ''
                }

                # if not specified, ensure 'Present'
                if (-not $i.ContainsKey('Ensure'))
                {
                    $i.Ensure = 'Present'
                }

                # this resource depends on the created directory
                $i.DependsOn = $dependsOnDirectory

                # create execution name for the resource
                $executionName = "$($myIni -replace '[-().:\s\\]', '_')_$($i.Key)"

                # create DSC resource for INI File
                $Splatting = @{
                    ResourceName  = 'IniFile'
                    ExecutionName = $executionName
                    Properties    = $i
                    NoInvoke      = $true
                }
                (Get-DscSplattedResource @Splatting).Invoke($i)
            } #end foreach

            <#
                create INI resource for POLLDIR key
            #>

            # create POLLDIR key value
            $value = 'C:\Users\{0}\AppData\Local\CACHE\PIACCT.PI' -f $u

            # create execution name for the resource
            $executionName = "$($myIni -replace '[-().:\s\\]', '_')_POLLDIR"
            
            IniFile "$executionName"
            {
                Path      = $myIni
                Key       = 'POLLDIR'
                Value     = $value
                Section   = ''
                Ensure    = 'Present'
                DependsOn = $dependsOnDirectory
            }
        } #end if
    } #end foreach
} #end configuration