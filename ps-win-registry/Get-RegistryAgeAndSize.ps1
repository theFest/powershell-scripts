Function Get-RegistryAgeAndSize {
    <#
    .SYNOPSIS
    Retrieves registry information including age and size from specified remote computers.

    .DESCRIPTION
    This function retrieves registry details, such as current size, maximum size, free space, percent free, age since installation, and status, from remote computers.

    .PARAMETER ComputerName
    Name of the remote computer(s) to retrieve registry information from.
    .PARAMETER User
    Specifies the username for authentication on remote computers.
    .PARAMETER Pass
    Specifies the password for authentication on remote computers.

    .EXAMPLE
    Get-RegistryAgeAndSize -ComputerName "remote_host" -Username "remote_user" -Pass "remote_pass"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]$ComputerName = $env:COMPUTERNAME,
        
        [Parameter(Mandatory = $false)]
        [string]$User,
        
        [Parameter(Mandatory = $false)]
        [string]$Pass
    )
    BEGIN {
        Write-Verbose -Message "Starting $($MyInvocation.MyCommand)"
        if ($User -or $Pass) {
            $SecurePassword = ConvertTo-SecureString -String $Pass -AsPlainText -Force
            $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $SecurePassword
        }
    }
    PROCESS {
        foreach ($Computer in $ComputerName) {
            Write-Verbose -Message "Processing $Computer..."
            try {
                $Data = Get-WmiObject -Class Win32_Registry -ComputerName $Computer -Credential $Credential -ErrorAction Stop
                $Data | Select-Object -Property @{Name = "ComputerName"; Expression = { $_.__SERVER } },
                Status, CurrentSize, MaximumSize, @{Name = "FreeSize"; Expression = { $_.MaximumSize - $_.CurrentSize } },
                @{Name = "PercentFree"; Expression = { (1 - ($_.CurrentSize / $_.MaximumSize)) * 100 } },
                @{Name = "Created"; Expression = { $_.ConvertToDateTime($_.InstallDate) } },
                @{Name = "Age"; Expression = { (Get-Date) - ( $_.ConvertToDateTime($_.InstallDate)) } }
            }
            catch {
                Write-Warning -Message "Failed to retrieve registry information from $($Computer.ToUpper())!"
                Write-Error -Exception $_.Exception.Message
            }
        }
    }
    END {
        Write-Verbose -Message "Ending $($MyInvocation.MyCommand)"
    }
}
