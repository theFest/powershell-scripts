#Requires -Version 3.0 -Modules ActiveDirectory
Function Set-ADGroupUserPicture {
    <#
    .SYNOPSIS
    Sets or removes profile pictures for Active Directory users based on group membership.

    .DESCRIPTION
    This function allows setting or removing profile pictures for Active Directory users based on their group membership.
    It takes two groups as input parameters: one for users who need to have a picture set and another for users who need their pictures removed. Pictures are sourced from a specified directory and are named after the user's SamAccountName with a given extension.

    .PARAMETER AddGroup
    Active Directory group containing users who need to have a profile picture set.
    .PARAMETER RemGroup
    Active Directory group containing users who need their profile picture removed.
    .PARAMETER PictureDir
    The directory path containing the profile pictures.
    .PARAMETER UPNDomain
    UPN default domain to be appended to the user's SamAccountName to form the User Principal Name (UPN).
    .PARAMETER Extension
    File extension of the profile pictures., supported formats are 'jpg', 'png', 'gif', and 'bmp'. The default extension is 'jpg'.
    .PARAMETER Workaround
    Enable a workaround using the Exchange Management PowerShell Snap-In.

    .EXAMPLE
    Set-ADGroupUserPicture -AddGroup "Marketing" -RemGroup "FormerEmployees" -PictureDir "C:\ProfilePictures" -Extension "jpg" -UPNDomain "contoso.com" -Verbose

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 1, HelpMessage = "AD Group with users that would like to have a picture")]
        [ValidateNotNullOrEmpty()]
        [Alias("a")]
        [string]$AddGroup,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 2, HelpMessage = "AD Group with users that would like have have the picture removed")]
        [ValidateNotNullOrEmpty()]
        [Alias("b")]
        [string]$RemGroup,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 3, HelpMessage = "Directory that contains the pictures")]
        [ValidateNotNullOrEmpty()]
        [Alias("p")]
        [string]$PictureDir,

        [Parameter(Mandatory = $false, Position = 5, HelpMessage = "Specify the UPN Default Domain")]
        [Alias("u")]
        [string]$UPNDomain,

        [Parameter(Mandatory = $false, Position = 4, HelpMessage = "Image file extension, supported formats: 'jpg', 'png', 'gif', 'bmp' (default: 'jpg')")]
        [ValidateSet("jpg", "png", "gif", "bmp")]
        [ValidateNotNullOrEmpty()]
        [Alias("e")]
        [string]$Extension = "jpg",

        [Parameter(Mandatory = $false, HelpMessage = "Use this switch(Exchange Management PowerShell Snap-In) to enable a workaround")]
        [Alias("w")]
        [switch]$Workaround = $false
    )
    BEGIN {
        if (-not (Get-Module -Name ExchangeOnlineManagement -ListAvailable)) {
            Write-Warning -Message "Exchange Management module is missing, installing ..."
            Install-Module -Name ExchangeOnlineManagement -Force -AllowClobber -Verbose
            return
        }
        $AddUserPixx = $null
        $NoUserPixx = $null
        $TestValidEmail = {
            param (
                [Parameter(Mandatory = $true, HelpMessage = "Address string to check")]
                [ValidateNotNullOrEmpty()]
                [string]$Address
            )
            ($Address -as [MailAddress]).Address -eq $Address -and $null -ne $Address
        }
        if ($Workaround) {
            Write-Verbose -Message "Adding Microsoft Exchange Management PowerShell Snap-In for Workaround"
            try {
                Add-PSSnapin -Name Microsoft.Exchange.Management.PowerShell.SnapIn -ErrorAction Stop
            }
            catch {
                Write-Verbose -Message "Failed to add Exchange Management PowerShell Snap-In: $_"
            }
        }
        if (-not ($PictureDir.EndsWith('\'))) {
            $PictureDir += '\'
            Write-Verbose -Message "Fixed the Source Directory String!"
        }
        try {
            $AddUserPixx = Get-ADGroupMember -Identity $AddGroup -ErrorAction Stop -WarningAction SilentlyContinue | Select-Object -ExpandProperty SamAccountName
        }
        catch {
            Write-Error -Message ('Unable to find {0}' -f $AddGroup) -ErrorAction Stop
            return
        }
        try {
            $NoUserPixx = Get-ADGroupMember -Identity $RemGroup -ErrorAction Stop -WarningAction SilentlyContinue | Select-Object -ExpandProperty SamAccountName
        }
        catch {
            Write-Error -Message ('Unable to find {0}' -f $AddGroup) -ErrorAction Stop
            return
        }
    }
    PROCESS {
        foreach ($AddUser in $AddUserPixx) {
            if (($NoUserPixx -notcontains $AddUser) -and (& $TestValidEmail -Address $AddUser)) {
                $AddUserUPN = if ($UPNDomain) { "$AddUser@$UPNDomain" } else { $AddUser }
                $SingleUserPicture = "$PictureDir$AddUser.$Extension"
                if (Test-Path -Path $SingleUserPicture -ErrorAction SilentlyContinue) {
                    try {
                        Set-ADUser -Identity $AddUserUPN -Replace @{thumbnailPhoto = [System.IO.File]::ReadAllBytes($SingleUserPicture) } -ErrorAction Stop -Verbose
                        Write-Verbose -Message "User photo set successfully for $AddUserUPN"
                    }
                    catch {
                        Write-Warning -Message ('Unable to set Image {0} for User {1}' -f $SingleUserPicture, $AddUserUPN) -ErrorAction Continue
                    }
                }
                else {
                    Write-Warning -Message ('The Image {0} for User {1} was not found' -f $SingleUserPicture, $AddUserUPN) -ErrorAction SilentlyContinue
                }
            }
            else {
                Write-Verbose -Message ('Sorry, User {0} is a member of both {1} and {2}' -f $AddUser, $AddGroup, $RemGroup)
            }
        }
        foreach ($NoUser in $NoUserPixx) {
            if (& $TestValidEmail -Address $NoUser) {
                $NoUserUPN = if ($UPNDomain) { "$NoUser@$UPNDomain" } else { $NoUser }
                try {
                    Set-ADUser -Identity $NoUserUPN -Clear thumbnailPhoto -ErrorAction Stop -Verbose
                    Write-Verbose -Message "User photo removed successfully for $NoUserUPN"
                }
                catch {
                    Write-Warning -Message ('Unable to handle {0} - Check that this user has a valid Mailbox!' -f $NoUser)
                }
            }
            else {
                Write-Error -Message "UPN Default Domain not set but needed!"
            }
        }
    }
    END {
        $AddUserPixx = $null
        $NoUserPixx = $null
        [System.GC]::Collect()
    }
}
