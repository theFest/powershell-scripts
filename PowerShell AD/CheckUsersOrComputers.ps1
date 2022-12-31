#requires -version 3.0
Function CheckUsersOrComputers {
    <#
    .SYNOPSIS
    Function for querying users or computers.
    
    .DESCRIPTION
    With this function you can query specific group for users or computer, and also export to csv.
    
    .PARAMETER Group
    Mandatory - description    
    .PARAMETER SearchBase
    Mandatory - enter your base, e.g. "OU=your_group,OU=your_city,OU=your_state,DC=your_domain,DC=your_dc"
    .PARAMETER CheckType
    Mandatory - choose what you want to lookup, either choose for computers or users
    .PARAMETER ExUsr
    NotMandatory - export users to csv file.
    .PARAMETER ExComp
    NotMandatory - export computers to csv file.
    
    .EXAMPLE
    CheckUsersOrComputers -CheckType Users -Verbose
    CheckUsersOrComputers -CheckType Computers -ExComp "$env:USERPROFILE\Desktop\ExComp.csv" -Verbose
    
    .NOTES
    Info: https://learn.microsoft.com/en-us/sysinternals/downloads/psloggedon
    v1
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Group,

        [Parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $false)]
        [string]$SearchBase,

        [Parameter(Position = 2, Mandatory = $true)]
        [ValidateSet("Users", "Computers")]
        [string]$CheckType,
        
        [Parameter(Mandatory = $false)]
        [string]$ExUsr,
        
        [Parameter(Mandatory = $false)]
        [string]$ExComp
    )
    BEGIN {
        Start-Transcript -Path "$env:TEMP\CheckUsersOrComputers.txt" -Force -Verbose
        if (!(Get-Module -Name ActiveDirectory -ListAvailable -Verbose)) {
            Write-Output "Active Directory module is missing, installing..."
            Import-Module -Name ActiveDirectory -Force -Verbose
        }
        Write-Verbose "Selected group details: $(Get-ADGroup -Filter { Name -like $GroupName })"     
    }
    PROCESS {
        switch ($CheckType) {
            "Users" {
                foreach ($Grp in $Group) {
                    $UsrProps = @(
                        "Name",
                        "Title",
                        "Mail",
                        "SamAccountName",
                        "Department",
                        "Mobile",
                        "TelephoneNumber"
                    )
                    $GetUsr = Get-ADGroupMember -Identity $Grp -Recursive `
                    | Get-ADUser -Properties $UsrProps | Sort-Object -Property { $_.Name }
                    if ($ExUsr) {
                        Write-Verbose "Exporting users from specified group..."  
                        $GetUsr | Export-CSV -Path $ExUsr -NoTypeInformation -Force
                    } 
                    $GetUsr | Format-Table "Name", "Title", "Mail", "SamAccountName", "Department", "Mobile", "TelephoneNumber" -AutoSize
                }
            }
            "Computers" {
                $GetC = Get-ADComputer -Filter * -SearchBase $SearchBase
                if (Test-Path -Path $ExComp) {
                    Write-Host "File(csv) is already present on location, deleting!" -ForegroundColor Yellow
                    Remove-Item -Path $ExComp -Verbose
                }
                foreach ($Gc in $GetC) {
                    $Properties = @(
                        "Name",
                        "IPv4Address",
                        "LastLogonDate",
                        "OperatingSystem",
                        "OperatingSystemVersion",
                        "LastLogonDate",
                        "LogonCount",
                        "BadLogonCount",
                        "IPv4Address",
                        "Enabled",
                        "whenCreated"
                    )
                    $GetComp = Get-ADComputer -Identity $Gc -Properties $Properties `
                    | Sort-Object -Property { $_.Name }
                    if ($ExComp) {
                        Write-Verbose "Exporting users from specified group..." 
                        $GetComp | Export-CSV -Path $ExComp -NoTypeInformation -Append
                        foreach ($G in $GetComp) { 
                            $GetComp | Format-Table "Name", "IPv4Address", "LastLogonDate", "OperatingSystem", "OperatingSystemVersion", "WhenCreated" -AutoSize
                        }
                    }
                }
            }
        }
        Stop-Transcript
    }
    END {
        Start-Transcript -Path "$env:TEMP\CheckUsersOrComputers.txt" -Append
        Clear-Variable -Name Group, GetUsr, GetComp -Force -ErrorAction SilentlyContinue
        Clear-History -Verbose
        Write-Host "Finished, stopping TS and exiting!" -ForegroundColor Cyan
        Stop-Transcript
    }
}
