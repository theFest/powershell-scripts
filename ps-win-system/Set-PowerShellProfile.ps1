Function Set-PowerShellProfile {
    <#
    .SYNOPSIS
    Manages PowerShell profiles including showing, creating, editing, and deleting.

    .DESCRIPTION
    This function allows you to manage PowerShell profiles. You can show the content of a profile, create a new one, edit an existing one using various editors, and delete a profile.

    .PARAMETER Action
    Action to perform on the PowerShell profile, options are 'Show', 'Create', 'Edit', or 'Delete'. Default is 'Show'.
    .PARAMETER Editor
    Text editor to use when editing the profile, options are 'Notepad', 'Notepad++', 'Visual Studio Code', 'Sublime Text', or 'Atom'. Default is 'Notepad'.
    .PARAMETER ProfileScope
    Scope of the PowerShell profile, options are 'CurrentUserCurrentHost', 'CurrentUserAllHosts', or 'AllUsersAllHosts'. Default is 'CurrentUserCurrentHost'.
    .PARAMETER Force
    Forces the creation of a new profile even if it already exists, applicable only when Action is 'Create'.

    .EXAMPLE
    Set-PowerShellProfile -Action Show

    .NOTES
    v0.0.7
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Show", "Create", "Edit", "Delete")]
        [string]$Action = "Show",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Notepad", "Notepad++", "Visual Studio Code", "Sublime Text", "Atom")]
        [string]$Editor = "Notepad",

        [Parameter(Mandatory = $false)]
        [ValidateSet("CurrentUserCurrentHost", "CurrentUserAllHosts", "AllUsersAllHosts")]
        [string]$ProfileScope = "CurrentUserCurrentHost",

        [Parameter(Mandatory = $false)]
        [switch]$Force = $false
    )
    switch ($Action) {
        "Show" {
            $ProfilePath = $PROFILE.$ProfileScope
            if (Test-Path -Path $ProfilePath -PathType Leaf) {
                $Content = Get-Content $ProfilePath
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
            if (!(Test-Path -Path $ProfilePath -PathType Leaf) -or $Force) {
                New-Item -Path $ProfilePath -ItemType File -Force:$Force -Verbose | Out-Null
            }
            else {
                Write-Warning -Message "PowerShell profile file already exists. Use -Force to overwrite."
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
                "Atom" {
                    if (!(Test-Path "$env:LOCALAPPDATA\atom\atom.exe" -PathType Leaf)) {
                        Write-Warning -Message "Atom is not installed, using Notepad instead"
                        $Editor = "Notepad"
                    }
                    else {
                        $EditorPath = "$env:LOCALAPPDATA\atom\atom.exe"
                    }
                    break
                }
                default {
                    $EditorPath = "$env:windir\System32\notepad.exe" ; break
                }
            }
            $ProfilePath = $PROFILE.$ProfileScope
            if (!(Test-Path -Path $ProfilePath -PathType Leaf)) {
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
            if (Test-Path -Path $ProfilePath -PathType Leaf) {
                Write-Verbose -Message "Deleting..."
                Remove-Item -Path $ProfilePath -Force -Verbose
            }
            else {
                Write-Warning -Message "PowerShell profile file $ProfilePath does not exist"
            }
            break
        }
        default {
            Write-Warning -Message "Invalid action specified. Valid options are 'Create', 'Edit', 'Delete', and 'Show'"
            break
        }
    }
}
