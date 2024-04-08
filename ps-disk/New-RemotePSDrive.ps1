Function New-RemotePSDrive {
    <#
    .SYNOPSIS
    Creates a PSDrive on a remote computer.

    .DESCRIPTION
    This function creates a PSDrive on a remote computer using PowerShell remoting.

    .PARAMETER Path
    Path for the PSDrive, default is the current location.
    .PARAMETER Name
    Specifies the name of the PSDrive.
    .PARAMETER ComputerName
    Specifies the name of the remote computer.
    .PARAMETER Username
    Username for authentication to the remote computer.
    .PARAMETER Pass
    Password for authentication to the remote computer.
    .PARAMETER First
    Selects the first word from the path to create the PSDrive name.

    .EXAMPLE
    New-RemotePSDrive -Path "C:\Temp" -Name "rPSD" -ComputerName "remote_host" -Username "remote_user" -Pass "remote_pass"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateScript({ 
                Test-Path -Path $_
            })]
        [string]$Path = ".",
        
        [Parameter(Mandatory = $false, Position = 1)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,

        [Parameter(Mandatory = $false)]
        [string]$Username,
        
        [Parameter(Mandatory = $false)]
        [string]$Pass,
    
        [Parameter(Mandatory = $false)]
        [switch]$First
    )
    BEGIN {
        $StartTime = Get-Date
        Write-Host "Script started at $StartTime" -ForegroundColor DarkCyan
        Write-Verbose -Message "Starting $($MyInvocation.Mycommand)"
        $Location = Get-Item -Path $Path
    }
    PROCESS {
        if (-not $Name) {
            $Pattern = if ($First) { "^\w+" } else { "\w+$" }
            if ($Location.Name -match $Pattern) {
                $Name = $matches[0]
            }
            else {
                Write-Warning -Message "$Path doesn't meet the criteria!"
                return
            }
        }
        $PSDriveParams = @{
            Name        = $Name
            PSProvider  = "FileSystem"
            Root        = $Path
            Description = "Created $(Get-Date)"
            Scope       = "Global"
            Credential  = $null
        }
        if ($Username -and $Pass) {
            $SecurePassword = ConvertTo-SecureString -String $Pass -AsPlainText -Force
            $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username, $SecurePassword
            $PSDriveParams.Credential = $Credential
        }
        Write-Host "Testing $($Name):" -ForegroundColor Cyan
        if (-not (Test-Path -Path "$($Name):")) {
            try {
                Write-Verbose -Message "Creating PSDrive for $Name on $ComputerName"
                $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential -ErrorAction Stop
                Invoke-Command -Session $Session -ScriptBlock {
                    param($PSDriveParams)
                    New-PSDrive @PSDriveParams
                } -ArgumentList $PSDriveParams -ErrorAction Stop      
            }
            catch {
                Write-Error -Message "Failed to create PSDrive on $ComputerName. $_"
            }
        }
        else {
            Write-Warning -Message "A PSDrive for $Name already exists!"
        }
    }
    END {
        if ($Session) {
            Remove-PSSession -Session $Session -Verbose
        }
        Write-Verbose -Message "Ending $($MyInvocation.Mycommand)"
        $EndTime = Get-Date
        $ExecutionTime = New-TimeSpan -Start $StartTime -End $EndTime
        Write-Host "Total execution time: $($ExecutionTime.TotalSeconds) seconds" -ForegroundColor DarkCyan
    }
}
