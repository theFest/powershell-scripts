function Set-VirtualMemory {
    <#
    .SYNOPSIS
    Configures virtual memory settings including automatic pagefile management and custom pagefile sizes.

    .DESCRIPTION
    This function allows you to manage virtual memory settings on a Windows computer.
    It can enable or disable automatic pagefile management, set custom pagefile sizes, and remove existing pagefiles.
    
    .EXAMPLE
    Set-VirtualMemory -ManageAutomaticPageFile On -Verbose                                      #-->(Auto Management/System managed size)
    Set-VirtualMemory -ManageAutomaticPageFile Off -InitialCustomSize 8192 -MaxCustomSize 32384 #-->(Custom Min/Max sizes)
    Set-VirtualMemory -ManageAutomaticPageFile Off -RemovePageFile                              #-->(Remove and delete a pagefile/No paging file)
    
    .NOTES
    v0.2.9
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, HelpMessage = "Enable or disable automatic pagefile management, values are 'On' or 'Off'")]
        [ValidateSet("On", "Off")]
        [string]$ManageAutomaticPageFile,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true, HelpMessage = "Initial size of the custom pagefile in megabytes")]
        [ValidateRange(2048, 8192)]
        [int]$InitialCustomSize,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true, HelpMessage = "Maximum size of the custom pagefile in megabytes")]
        [ValidateRange(8192, 131072)]
        [int]$MaxCustomSize,
      
        [Parameter(Mandatory = $false, HelpMessage = "Indicates whether to remove the existing pagefile")]
        [switch]$RemovePageFile,

        [Parameter(Mandatory = $false, HelpMessage = "Path to the pagefile, default is 'C:\pagefile.sys'")]
        [string]$PageFilePath = "C:\pagefile.sys"
    )
    try {
        $ComputerSystem = Get-WmiObject -Class Win32_ComputerSystem -EnableAllPrivileges -ErrorAction Stop
        switch ($ManageAutomaticPageFile) {
            "On" {
                $ComputerSystem.AutomaticManagedPagefile = $true
                Write-Verbose -Message "Automatic pagefile management enabled"
            }
            "Off" {
                $ComputerSystem.AutomaticManagedPagefile = $false
                Write-Verbose -Message "Automatic pagefile management disabled"
            }
            default {
                throw "Invalid value for 'ManageAutomaticPageFile', values are 'On' or 'Off'!"
            }  
        }
        $ComputerSystem.Put() | Out-Null
        if ($InitialCustomSize -and $MaxCustomSize) {
            $PageFileSettings = Get-WmiObject -Class Win32_PageFileSetting -ErrorAction SilentlyContinue
            if ($PageFileSettings) {
                Write-Verbose -Message "Setting custom pagefile management"
                $PageFileSettings.InitialSize = $InitialCustomSize
                $PageFileSettings.MaximumSize = $MaxCustomSize
                $PageFileSettings.Put() | Out-Null
            }
            else {
                throw "Failed to retrieve page file settings"
            }
        }
        if ($RemovePageFile) {
            $PageFileSettings = Get-WmiObject -Class Win32_PageFileSetting -ErrorAction SilentlyContinue
            if ($PageFileSettings) {
                Write-Verbose -Message "Disabling and deleting a single pagefile.sys"
                $PageFileSettings.Delete() | Out-Null
            }
            else {
                Write-Warning -Message "No page file found to remove"
            }
        }
    }
    catch {
        Write-Error -Message $_.Exception.Message
    }
}
