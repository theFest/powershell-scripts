Function Watch-ADGroupsChanges {
    <#
    .SYNOPSIS
    Monitors Active Directory group membership changes and sends email notifications.

    .DESCRIPTION
    This function monitors changes in Active Directory group memberships and sends email notifications for detected changes. It compares the current group members with the previous state and logs the changes to a CSV file.

    .PARAMETER LogsPath
    Specifies the path where logs and CSV files will be stored.
    .PARAMETER DateFormat
    Date format used in timestamping log files and CSV files.
    .PARAMETER CsvDelimiter
    Specifies the delimiter to be used in CSV files.
    .PARAMETER BackupPreviousMembers
    If used, backs up the previous group members CSV file.
    .PARAMETER IncludeGroups
    Array of group names to include in the monitoring.
    .PARAMETER ExcludeGroups
    Array of group names to exclude from the monitoring.
    .PARAMETER CurrentMembersCsvPath
    Path for the CSV file containing the current group members.
    .PARAMETER PreviousMembersCsvPath
    Path for the CSV file containing the previous group members.
    .PARAMETER SkipExistingMembersCsv
    If used, skips creating a new CSV file if it already exists.
    .PARAMETER SendEmailOnChanges
    If used, sends email notifications on detected group membership changes.
    .PARAMETER EmailFrom
    Specifies the sender's email address for notification emails.
    .PARAMETER EmailTo
    Recipient's email address for notification emails.
    .PARAMETER SmtpServer
    The SMTP server to be used for sending notification emails.
    .PARAMETER SmtpPort
    Port number to be used for the SMTP server.

    .EXAMPLE
    Watch-ADGroupsChanges -LogsPath "C:\Logs" -CsvDelimiter ',' -BackupPreviousMembers -IncludeGroups "include_group1", "include_group2" -ExcludeGroups "exclude_group" -SkipExistingMembersCsv
    
    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$LogsPath = "$env:SystemDrive\Temp\Logs",
    
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^\d{2}-\d{2}-\d{4}-\d{4}$')]
        [string]$DateFormat = 'dd-MM-yyyy-HHMM',
    
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet(';', ',', '|')]
        [string]$CsvDelimiter = ';',
    
        [Parameter(Mandatory = $false)]
        [switch]$BackupPreviousMembers,
    
        [Parameter(Mandatory = $false)]
        [string[]]$IncludeGroups = @(),
    
        [Parameter(Mandatory = $false)]
        [string[]]$ExcludeGroups = @(),
    
        [Parameter(Mandatory = $false)]
        [string]$CurrentMembersCsvPath = "$LogsPath\currentmembers.csv",
    
        [Parameter(Mandatory = $false)]
        [string]$PreviousMembersCsvPath = "$LogsPath\previousmembers.csv",
    
        [Parameter(Mandatory = $false)]
        [switch]$SkipExistingMembersCsv,

        [Parameter(Mandatory = $false)]
        [switch]$SendEmailOnChanges,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')]
        [string]$EmailFrom = "email_from@domain.com",
    
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')]
        [string]$EmailTo = "email@domain.com",
    
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$SmtpServer = "emailserver.domain.local",
    
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 65535)]
        [int]$SmtpPort = 25
    )
    BEGIN {
        if (-not (Test-Path -Path $LogsPath -PathType Any)) {
            New-Item -Path $LogsPath -ItemType Directory | Out-Null
        }
        Start-Transcript -Path "$LogsPath\ad_group_change.log" -Append
        $Date = Get-Date -Format $DateFormat
        $AdminGroups = Get-ADGroup -Filter * | Where-Object {
            ($IncludeGroups.Count -eq 0 -or $_.Name -in $IncludeGroups) -and
            ($ExcludeGroups.Count -eq 0 -or $_.Name -notin $ExcludeGroups)
        } | Select-Object -ExpandProperty Name
        if ($BackupPreviousMembers -and (Test-Path -Path $PreviousMembersCsvPath -ErrorAction SilentlyContinue)) {
            Write-Host ("- Renaming previousmembers.csv to {0}_previousmembers.csv" -f $Date) -ForegroundColor Green
            Move-Item -Path $PreviousMembersCsvPath -Destination "$LogsPath\$($Date)_previousmembers.csv" -Confirm:$false -Force:$true -Verbose
        }
        if (-not $SkipExistingMembersCsv -or -not (Test-Path -Path $CurrentMembersCsvPath -ErrorAction SilentlyContinue)) {
            if (Test-Path -Path $CurrentMembersCsvPath -ErrorAction SilentlyContinue) {
                Write-Host ("- Renaming currentmembers.csv to previousmembers.csv") -ForegroundColor Green
                Move-Item -Path $CurrentMembersCsvPath -Destination $PreviousMembersCsvPath -Confirm:$false -Force:$true -Verbose
            }
            $Members = @()
            foreach ($AdminGroup in $AdminGroups) {
                Write-Host ("- Checking {0}" -f $AdminGroup) -ForegroundColor Green
                try {
                    $AdminGroupMembers = Get-ADGroupMember -Identity $AdminGroup -Recursive -ErrorAction Stop | Sort-Object SamAccountName
                }
                catch {
                    Write-Warning -Message ("Members of {0} can't be retrieved, skipping..." -f $AdminGroup)
                    $AdminGroupMembers = $null
                }
                if ($null -ne $AdminGroupMembers) {
                    foreach ($AdminGroupMember in $AdminGroupMembers) {
                        Write-Host ("- Adding {0} to list" -f $AdminGroupMember.SamAccountName) -ForegroundColor Green
                        $Members += [PSCustomObject]@{
                            Group  = $AdminGroup
                            Member = $AdminGroupMember.SamAccountName
                        }
                    }
                }
            }
            Write-Host "- Exporting results to $CurrentMembersCsvPath" -ForegroundColor Green
            $Members | Export-Csv -Path $CurrentMembersCsvPath -NoTypeInformation -Encoding UTF8 -Delimiter $CsvDelimiter -Verbose
        }
    }
    END {
        if ($BackupPreviousMembers -and -not (Test-Path $PreviousMembersCsvPath)) {
            $Members | Export-Csv -Path $PreviousMembersCsvPath -NoTypeInformation -Encoding UTF8 -Delimiter $CsvDelimiter -Verbose
        }
        $CurrentMembers = Import-Csv -Path $CurrentMembersCsvPath -Delimiter $CsvDelimiter
        $PreviousMembers = Import-Csv -Path $PreviousMembersCsvPath -Delimiter $CsvDelimiter
        Write-Host "- Comparing current members to the previous members" -ForegroundColor Green
        $Compare = Compare-Object -ReferenceObject $PreviousMembers -DifferenceObject $CurrentMembers -Property Group, Member
        if ($null -ne $Compare) {
            $DifferenceTotal = foreach ($Change in $Compare) {
                if ($Change.SideIndicator -match ">") {
                    $Action = "Added"
                }
                if ($Change.SideIndicator -match "<") {
                    $Action = "Removed"
                }
                [PSCustomObject]@{
                    Date   = $Date
                    Group  = $Change.Group
                    Action = $Action
                    Member = $Change.Member
                }
            }
            $DifferenceTotal | Sort-Object Group | Out-File "$LogsPath\$($Date)_changes.txt" -Verbose
            Write-Host "- Emailing detected changes" -ForegroundColor Green
            if ($SendEmailOnChanges) {
                $Body = Get-Content "$LogsPath\$($Date)_changes.txt" | Out-String
                $Options = @{
                    Body        = $Body
                    ErrorAction = "Stop"
                    From        = $EmailFrom
                    Priority    = "High"
                    Subject     = "Admin group change detected"
                    SmtpServer  = $SmtpServer
                    Port        = $SmtpPort
                    To          = $EmailTo
                }
                try {
                    Send-MailMessage @Options -Verbose
                }
                catch {
                    Write-Warning -Message "- Error sending email, please check the email options!"
                }
            }
        }
        else {
            Write-Host "No changes detected" -ForegroundColor DarkGreen
        }
        Stop-Transcript -Verbose
    }
}
