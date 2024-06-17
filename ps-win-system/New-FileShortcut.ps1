#requires -Version 2.0
function New-FileShortcut {
    <#
    .SYNOPSIS
    Creates a new shortcut (.lnk) file on the desktop pointing to a specified target file.

    .DESCRIPTION
    This function creates a new Windows shortcut (.lnk) file, allows specifying name of the shortcut and the full path to the target file. Optionally, it can return the created shortcut object and overwrite an existing shortcut if specified.

    .EXAMPLE
    New-FileShortcut -Name "7-Zip.lnk" -Target "C:\Program Files\7-Zip\7zFM.exe" -Force -Verbose

    .NOTES
    v0.4.9
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Low")]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Enter the name of the file shortcut, must end in .lnk")]
        [ValidateScript({ $_ -match '\.lnk$' })]
        [string]$Name,

        [Parameter(Mandatory = $true, HelpMessage = "Enter the full path to the target file shortcut, file must already exist")]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]$Target,

        [Parameter(HelpMessage = "Indicates whether to return the created shortcut object")]
        [switch]$PassThru,

        [Parameter(HelpMessage = "Allows overwriting an existing shortcut file if it already exists")]
        [switch]$Force
    )
    BEGIN {
        $WShell = New-Object -ComObject "Wscript.Shell"
        Set-Location -Path "$env:USERPROFILE\Desktop"
    }
    PROCESS {
        Write-Verbose -Message "Creating shortcut: $Target as $Name"
        $LinkPath = if (Test-Path -Path $Name -PathType Container) {
            $Name
        }
        else {
            Join-Path -Path (Get-Location) -ChildPath $Name
            Write-Verbose "Adjusted link file path to: $LinkPath"
        }
        if ((Test-Path -Path $LinkPath -PathType Leaf) -and (!$Force)) {
            Write-Warning "Shortcut '$LinkPath' already exists, use -Force to overwrite!"
            return
        }
        $Shortcut = $WShell.CreateShortcut($LinkPath)
        $Shortcut.TargetPath = $Target
        if ($PSCmdlet.ShouldProcess($Target, "Create shortcut")) {
            $Shortcut.Save()
            Write-Verbose -Message "Shortcut saved to: $($Shortcut.FullName)"
            if ($PassThru) {
                Get-Item -Path $Shortcut.FullName
            }
        }
    }
    END {
        Remove-variable WShell -Confirm:$false
    }
}
