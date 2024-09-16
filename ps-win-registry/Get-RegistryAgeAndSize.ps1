function Get-RegistryAgeAndSize {
    <#
    .SYNOPSIS
    Retrieves the size, free space, and age of the registry on one or more remote or local computers.

    .DESCRIPTION
    This function retrieves information about the Windows registry, including the current size, maximum size, free space, and the age of the registry since its installation on the specified computer(s).

    .EXAMPLE
    Get-RegistryAgeAndSize -Verbose
    Get-RegistryAgeAndSize -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass"

    .NOTES
    v0.2.3
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Specify the computer name(s)")]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false, HelpMessage = "Username for remote authentication, if not provided, the current user is assumed")]
        [string]$User,

        [Parameter(Mandatory = $false, HelpMessage = "Password for remote authentication, must be used in conjunction with the User parameter")]
        [string]$Pass
    )
    BEGIN {
        Write-Verbose -Message "Starting function: $($MyInvocation.MyCommand)"
        if ($User -and $Pass) {
            try {
                $SecurePassword = ConvertTo-SecureString -String $Pass -AsPlainText -Force
                $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $SecurePassword
                Write-Verbose -Message "Credentials created successfully."
            }
            catch {
                Write-Error -Message "Failed to create credentials: $_"
                return
            }
        }
    }
    PROCESS {
        foreach ($Computer in $ComputerName) {
            Write-Verbose -Message "Processing computer: $Computer"
            try {
                if ($Credential) {
                    $Data = Get-WmiObject -Class Win32_Registry -ComputerName $Computer -Credential $Credential -ErrorAction Stop
                }
                else {
                    $Data = Get-WmiObject -Class Win32_Registry -ComputerName $Computer -ErrorAction Stop
                }
                $Results = $Data | Select-Object -Property @{
                    Name = "ComputerName"; Expression = { $_.__SERVER }
                }, Status, CurrentSize, MaximumSize, @{
                    Name = "FreeSize"; Expression = { $_.MaximumSize - $_.CurrentSize }
                }, @{
                    Name = "PercentFree"; Expression = { (1 - ($_.CurrentSize / $_.MaximumSize)) * 100 }
                }, @{
                    Name = "Created"; Expression = { $_.ConvertToDateTime($_.InstallDate) }
                }, @{
                    Name = "Age"; Expression = { (Get-Date) - $_.ConvertToDateTime($_.InstallDate) }
                }
                Write-Output -InputObject $Results
            }
            catch {
                Write-Warning -Message "Failed to retrieve registry information from $Computer."
                Write-Error -Message "Error details: $($_.Exception.Message)"
            }
        }
    }

    END {
        Write-Verbose -Message "Completed function: $($MyInvocation.MyCommand)"
    }
}
