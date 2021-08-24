Function SetVirtualMemory {
    <#
    .SYNOPSIS
    Manage virtual memory on Windows machines.
    
    .DESCRIPTION
    With this function you can set, remove or disable VM on Win7/Win10.
    
    .PARAMETER Manage
    Mandatory - choose between automatic($true) and manual($false), see examples.     
    .PARAMETER InitialCustomSize
    NotMandatory - declare minimum custom VM size, you can choose between 1024-4096 MB. You can also parametrize your range.    
    .PARAMETER MaxCustomSize
    NotMandatory - declare maximum custom VM size, you can choose between 4096-32768 MB. You can also parametrize your range.   
    .PARAMETER RemovePageFile
    NotMandatory - remove, delete and disable pagefile. Not recommended because of potential system instability, restart is necessary.
    
    .EXAMPLE
    SetVirtualMemory -Manage true -Verbose  ##-->(Auto Management/System managed size)
    SetVirtualMemory -Manage false -InitialCustomSize 1024 -MaxCustomSize 8096 -Verbose  ##-->(Custom Min/Max sizes)
    SetVirtualMemory -Manage false -RemovePageFile -Verbose  ##-->(Remove and delete a pagefile/No paging file)
    
    .NOTES
    v1
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateSet("True", "False")]
        [string]$Manage,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [ValidateRange(1024, 4096)]$InitialCustomSize,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [ValidateRange(4096, 32768)]$MaxCustomSize,
      
        [Parameter(Mandatory = $false)]
        [switch]$RemovePageFile
    )
    $ComputerSystem = Get-WmiObject -Class Win32_ComputerSystem -EnableAllPrivileges
    switch ($Manage) {
        ## "Disable/Enable automatic pagefile management."
        'True' { $ComputerSystem.AutomaticManagedPagefile = $true } 
        'False' { $ComputerSystem.AutomaticManagedPagefile = $false }
        default { Write-Verbose -Message "Incorrect operation has executed." }  
    }
    Write-Verbose -Message "Setting for automatic pagefile management has changed to $Manage."
    $ComputerSystem.Put() | Out-Null
    $PFS = Get-WmiObject -Class Win32_PageFileSetting
    if ($PFS) {
        #$PFSM = Set-WmiInstance Win32_PageFileSetting -Arguments @{Name='C:\pagefile.sys'; InitialSize=0; MaximumSize=0}
        Write-Verbose -Message "Setting custom pagefile management."
        $PFS.InitialSize = $InitialCustomSize
        $PFS.MaximumSize = $MaxCustomSize
        $PFS.Put() | Out-Null
    }
    if ($RemovePageFile) {
        Write-Verbose -Message "Disabling and deleting a single pagefile.sys if any."
        $PFS.Delete()
    }
}