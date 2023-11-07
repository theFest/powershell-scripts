Function Manage-PSProfile {
    <#
    .SYNOPSIS
    Manages the PowerShell ISE profile.

    .DESCRIPTION
    This function has four main actions: Show, Create, Edit, and Delete for PS ISE profile management.

    .PARAMETER Action
    NotMandatory - specifies the action to perform, default is Show.
    .PARAMETER Editor
    NotMandatory - editor to use for editing the profile, default is Notepad.
    .PARAMETER ProfileScope
    NotMandatory - specifies the scope of the profile file, default is CurrentUserCurrentHost.

    .EXAMPLE
    Manage-PSProfile -Action Show
    Manage-PSProfile -Action Create
    Manage-PSProfile -Action Edit -Editor Notepad++
    Manage-PSProfile -Action Delete -Verbose

    .NOTES
    0.0.2
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Show", "Create", "Edit", "Delete")]
        [string]$Action = "Show",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Notepad", "Notepad++", "Visual Studio Code", "Sublime Text")]
        [string]$Editor = "Notepad",

        [Parameter(Mandatory = $false)]
        [ValidateSet("CurrentUserCurrentHost", "CurrentUserAllHosts", "AllUsersAllHosts")]
        [string]$ProfileScope = "CurrentUserCurrentHost"
    )
    switch ($Action) {
        "Show" {
            $ProfilePath = $PROFILE.$ProfileScope
            if (Test-Path $ProfilePath -PathType Leaf) {
                $content = Get-Content $ProfilePath
                Write-Host "PowerShell profile file: `n$ProfilePath"
                Write-Output -InputObject $Content
            }
            else {
                Write-Warning -Message "PowerShell profile file $ProfilePath does not exist"
            }
            break
        }
        "Create" {
            $ProfilePath = $PROFILE.$ProfileScope
            if (!(Test-Path $ProfilePath -PathType Leaf)) {
                New-Item $ProfilePath -ItemType File -Force -Verbose | Out-Null
            }
            break
        }
        "Edit" {
            switch ($Editor) {
                "Notepad++" {
                    if (!(Test-Path "$env:ProgramFiles\Notepad++\notepad++.exe" -PathType Leaf)) {
                        Write-Warning -Message "Notepad++ is not installed, using Notepad instead"
                        $Editor = "Notepad"
                    }
                    else {
                        $EditorPath = "$env:ProgramFiles\Notepad++\notepad++.exe"
                    }
                    break
                }
                "Visual Studio Code" {
                    if (!(Test-Path "$env:ProgramFiles\Microsoft VS Code\code.exe" -PathType Leaf)) {
                        Write-Warning -Message "VS Code is not installed system wide, checking user..."
                    }
                    elseif (!(Test-Path "$env:LOCALAPPDATA\Programs\Microsoft VS Code\code.exe" -PathType Leaf)) {
                        Write-Warning -Message "VS Code(User) is not installed, using Notepad instead"
                    }
                    else {
                        $Editor = "Notepad"
                    }
                    break
                }
                "Sublime Text" {
                    if (!(Test-Path "$env:ProgramFiles\Sublime Text 3\sublime_text.exe" -PathType "Leaf")) {
                        Write-Warning -Message "Sublime Text is not installed, using Notepad instead"
                    }
                    else {
                        $Editor = "Notepad"
                    }
                    break
                }
                default {
                    $EditorPath = "$env:windir\System32\notepad.exe" ; break
                }
            }
            $ProfilePath = $PROFILE.$ProfileScope
            if (!(Test-Path $ProfilePath -PathType Leaf)) {
                New-Item $ProfilePath -ItemType File -Force -Verbose
            }
            $Params = @{
                FilePath     = $EditorPath
                ArgumentList = @(
                    $ProfilePath
                    "-NoProfile"
                    "-NoExit"
                    "-Command"
                    "& { $host.UI.RawUI.WindowTitle = 'PowerShell ISE'; Set-Location $pwd; Set-PSReadlineOption -EditMode Emacs }"
                )
            }
            if ($ProfileScope -eq "CurrentUserAllHosts") {
                $Params["ArgumentList"] += "-Scope", "CurrentUserAllHosts"
            }
            elseif ($ProfileScope -eq 'AllUsersAllHosts') {
                $Params["ArgumentList"] += "-Scope", "AllUsersAllHosts"
            }
            Write-Verbose -Message "Editing profile..."
            Start-Process @Params -Wait ; break
        }
        "Delete" {
            $ProfilePath = $PROFILE.$ProfileScope
            if (Test-Path $ProfilePath -PathType Leaf) {
                Write-Verbose -Message "Deleting..."
                Remove-Item $ProfilePath -Force -Verbose
            }
            break
        }
        default {
            Write-Warning -Message "Invalid action specified. Valid options are 'Create', 'Edit', 'Delete', and 'Show'"
            break
        }
    }
}
