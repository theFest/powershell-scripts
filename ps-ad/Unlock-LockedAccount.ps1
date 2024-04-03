Function Unlock-LockedAccount {
    <#
    .SYNOPSIS
    Retrieves information about Active Directory user lockouts.

    .DESCRIPTION
    This function retrieves information about Active Directory user lockouts by querying lockout events in the security logs of domain controllers. It can be used to identify the users who have been locked out of their accounts and the corresponding lockout events.

    .PARAMETER Identity
    User identity for which lockout information should be retrieved. This parameter is optional. If not provided, lockout information for all users within the specified time range will be returned.
    .PARAMETER StartTime
    Start time from which lockout events should be queried. This parameter is optional and defaults to 8 days ago from the current date.
    .PARAMETER EndTime
    End time until which lockout events should be queried. This parameter is optional and defaults to 1 day ago from the current date.

    .EXAMPLE
    Unlock-LockedAccount -Identity "ad_username"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding(DefaultParameterSetName = "All", ConfirmImpact = "None")]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ParameterSetName = "ByUser")]
        [Alias("i")]
        [string]$Identity,

        [Parameter(Mandatory = $false)]
        [Alias("s")]
        [datetime]$StartTime = (Get-Date).AddDays(-8),

        [Parameter(Mandatory = $false)]
        [Alias("e")]
        [datetime]$EndTime = (Get-Date).AddDays(-1)
    )
    BEGIN {
        $FilterHt = @{
            LogName = 'Security'
            ID      = 4740
        }
        if ($PSBoundParameters.ContainsKey("StartTime")) {
            $FilterHt["StartTime"] = $StartTime
        }
        if ($PSBoundParameters.ContainsKey("EndTime")) {
            $FilterHt["EndTime"] = $EndTime
        }
        try {
            $PDCEmulator = ((Get-ADDomain -ErrorAction Stop).PDCEmulator)
            Write-Verbose -Message ('Use {0} to find the lockout events' -f $PDCEmulator)
            $Events = (Get-WinEvent -ComputerName $PDCEmulator -FilterHashtable $FilterHt -ErrorAction Stop)
        }
        catch {
            [Management.Automation.ErrorRecord]$ErrorRec = $_
            $Info = [PSCustomObject]@{
                Exception = $ErrorRec.Exception.Message
                Reason    = $ErrorRec.CategoryInfo.Reason
                Target    = $ErrorRec.CategoryInfo.TargetName
                Script    = $ErrorRec.InvocationInfo.ScriptName
                Line      = $ErrorRec.InvocationInfo.ScriptLineNumber
                Column    = $ErrorRec.InvocationInfo.OffsetInLine
            }
            $Info | Out-String | Write-Verbose
            Write-Error -Message $ErrorRec.Exception.Message -ErrorAction Stop -Exception $ErrorRec.Exception -TargetObject $ErrorRec.CategoryInfo.TargetName
            break
        }
        Write-Verbose -Message "Found the following events: $Events"
    }
    PROCESS {
        if ($PSCmdlet.ParameterSetName -eq "ByUser") {
            try {
                Write-Verbose -Message ('Querry AD Info for {0}' -f $Identity)
                $User = (Get-ADUser -Identity $Identity -ErrorAction Stop)
                Write-Verbose -Message ('Found the following AD Info for {0}:' -f $Identity)
                Write-Host $User -ForegroundColor DarkCyan
                $Output = $Events | Where-Object -FilterScript {
                    $PSItem.Properties[0].Value -eq $User.SamAccountName
                }
            }
            catch {
                [Management.Automation.ErrorRecord]$ErrorRec = $_
                $Info = [PSCustomObject]@{
                    Exception = $ErrorRec.Exception.Message
                    Reason    = $ErrorRec.CategoryInfo.Reason
                    Target    = $ErrorRec.CategoryInfo.TargetName
                    Script    = $ErrorRec.InvocationInfo.ScriptName
                    Line      = $ErrorRec.InvocationInfo.ScriptLineNumber
                    Column    = $ErrorRec.InvocationInfo.OffsetInLine
                }
                $Info | Out-String | Write-Verbose
                Write-Error -Message $ErrorRec.Exception.Message -ErrorAction Stop -Exception $ErrorRec.Exception -TargetObject $ErrorRec.CategoryInfo.TargetName
                break
            }
        }
        else {
            $Output = $Events
        }
        foreach ($Event in $Output) {
            [PSCustomObject]@{
                UserName       = $Event.Properties[0].Value
                CallerComputer = $Event.Properties[1].Value
                TimeStamp      = $Event.TimeCreated
            }
        }
    }
    END {
        if ($Identity) {
            try {
                $User = Get-ADUser -Identity $Identity -Properties LockedOut -ErrorAction Stop
                if ($User.LockedOut) {
                    Write-Host "User $Identity is currently locked out!" -ForegroundColor DarkYellow
                    $Choice = Read-Host "Do you want to unlock user $Identity? (Y/N)"
                    if ($Choice -eq "Y" -or $Choice -eq "y") {
                        Unlock-ADAccount -Identity $Identity -Verbose
                        Write-Host "User $Identity has been successfully unlocked" -ForegroundColor Green
                    }
                    else {
                        Write-Host "No action taken." -ForegroundColor Cyan
                    }
                }
                else {
                    Write-Host "User $Identity is not locked out" -ForegroundColor DarkGreen
                }
            }
            catch {
                Write-Host "Error: $_" -ForegroundColor DarkMagenta
            }
        }
    }
}
