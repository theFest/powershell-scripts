#Requires -Version 2.0
Function New-FileShortcut {
    <#
    .SYNOPSIS
    Creates a new file shortcut (.lnk).
    
    .DESCRIPTION
    This function generates a file shortcut (.lnk) for a specified target file.
    
    .PARAMETER Name
    Name of the file shortcut.
    .PARAMETER Target
    Full path to the target file.
    .PARAMETER PassThru
    Return the created shortcut object.
    
    .EXAMPLE
    New-FileShortcut -Name "MyShortcut.lnk" -Target "C:\Path\To\Target\File.exe"
    
    .NOTES
    v0.0.1
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Low")]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, Position = 0, HelpMessage = "Enter the name of the file shortcut. It must end in .lnk")]
        [ValidateScript({ 
                $_.EndsWith(".lnk")
            })]
        [string]$Name,
        
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, Position = 1, HelpMessage = "Enter the full path to the target file shortcut. The file must already exist")]
        [ValidateScript({ 
                Test-Path -Path $_
            })]
        [string]$Target,
          
        [Parameter(Mandatory = $false, HelpMessage = "Enter a valid value for PassThru (e.g., -PassThru)")]
        [switch]$PassThru
    )
    BEGIN {
        $WShell = New-Object -ComObject "Wscript.Shell"
    }
    PROCESS {
        Write-Verbose -Message "Creating shortcut: $Target as $Name..."
        if (Split-Path $Name -Parent) {
            $LinkPath = $Name
        }
        else {
            $LinkPath = Join-Path -Path (Get-Location) $Name
            Write-Verbose -Message "Adjusting link file to $LinkPath..."
        }
        $Shortcut = $WShell.CreateShortcut($LinkPath)
        $Shortcut.TargetPath = $Target
        if ($PSCmdlet.ShouldProcess($Target)) {
            Write-Verbose -Message "Saving shortcut..."
            $Shortcut.Save()
            if ($PassThru) {
                Get-Item -Path $Shortcut.Fullname -Verbose
            }
        }
    }
    END {
        Remove-variable WShell -Confirm:$false
    }
}
