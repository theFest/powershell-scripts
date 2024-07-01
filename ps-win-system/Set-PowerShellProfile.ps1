function Set-PowerShellProfile {
    <#
    .SYNOPSIS
    Manages PowerShell profile files for the current or all users and hosts.

    .DESCRIPTION
    This function allows you to manage PowerShell profile files by performing actions such as showing, creating, editing, or deleting the profile files. You can specify the scope of the profile file and the text editor to use when editing the profile.

    .EXAMPLE
    Set-PowerShellProfile -Action Show

    .NOTES
    v0.4.0
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Specify the action to perform on the PowerShell profile")]
        [ValidateSet("Show", "Create", "Edit", "Delete")]
        [Alias("a")]
        [string]$Action = "Show",

        [Parameter(Mandatory = $false, HelpMessage = "Specify the editor to use when editing the PowerShell profile")]
        [ValidateSet("Notepad", "Notepad++", "Visual Studio Code", "Sublime Text", "Atom")]
        [Alias("e")]
        [string]$Editor = "Notepad",

        [Parameter(Mandatory = $false, HelpMessage = "Specify the scope of the PowerShell profile")]
        [ValidateSet("CurrentUserCurrentHost", "CurrentUserAllHosts", "AllUsersAllHosts")]
        [Alias("p")]
        [string]$ProfileScope = "CurrentUserCurrentHost",

        [Parameter(Mandatory = $false, HelpMessage = "Force the action, such as overwriting an existing profile file")]
        [Alias("f")]
        [switch]$Force = $false
    )
    $ProfilePath = $PROFILE.$ProfileScope
    switch ($Editor) {
        "Notepad++" {
            $EditorPath = "$env:ProgramFiles\Notepad++\notepad++.exe"
            if (-not (Test-Path $EditorPath -PathType Leaf)) {
                Write-Warning -Message "Notepad++ is not installed, using Notepad instead"
                $EditorPath = "$env:windir\System32\notepad.exe"
            }
            break
        }
        "Visual Studio Code" {
            $EditorPath = "$env:ProgramFiles\Microsoft VS Code\code.exe"
            if (-not (Test-Path $EditorPath -PathType Leaf)) {
                $EditorPath = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\code.exe"
                if (-not (Test-Path $EditorPath -PathType Leaf)) {
                    Write-Warning -Message "VS Code is not installed, using Notepad instead"
                    $EditorPath = "$env:windir\System32\notepad.exe"
                }
            }
            break
        }
        "Sublime Text" {
            $EditorPath = "$env:ProgramFiles\Sublime Text 3\sublime_text.exe"
            if (-not (Test-Path $EditorPath -PathType Leaf)) {
                Write-Warning -Message "Sublime Text is not installed, using Notepad instead"
                $EditorPath = "$env:windir\System32\notepad.exe"
            }
            break
        }
        "Atom" {
            $EditorPath = "$env:LOCALAPPDATA\atom\atom.exe"
            if (-not (Test-Path $EditorPath -PathType Leaf)) {
                Write-Warning -Message "Atom is not installed, using Notepad instead"
                $EditorPath = "$env:windir\System32\notepad.exe"
            }
            break
        }
        default {
            $EditorPath = "$env:windir\System32\notepad.exe"
            break
        }
    }
    switch ($Action) {
        "Show" {
            if (Test-Path -Path $ProfilePath -PathType Leaf) {
                $Content = Get-Content $ProfilePath
                Write-Host "PowerShell profile file: `n$ProfilePath" -ForegroundColor DarkCyan
                Write-Output -InputObject $Content
            }
            else {
                Write-Warning -Message "PowerShell profile file $ProfilePath does not exist!"
            }
            break
        }
        "Create" {
            if (-not (Test-Path -Path $ProfilePath -PathType Leaf) -or $Force) {
                New-Item -Path $ProfilePath -ItemType File -Force:$Force -Verbose | Out-Null
            }
            else {
                Write-Warning -Message "PowerShell profile file already exists. Use -Force to overwrite"
            }
            break
        }
        "Edit" {
            if (-not (Test-Path -Path $ProfilePath -PathType Leaf)) {
                New-Item -Path $ProfilePath -ItemType File -Force -Verbose | Out-Null
            }
            Start-Process -FilePath $EditorPath -ArgumentList $ProfilePath
            break
        }
        "Delete" {
            if (Test-Path -Path $ProfilePath -PathType Leaf) {
                Remove-Item -Path $ProfilePath -Force -Verbose
            }
            else {
                Write-Warning -Message "PowerShell profile file $ProfilePath does not exist!"
            }
            break
        }
        default {
            Write-Warning -Message "Invalid action specified!"
            break
        }
    }
}
