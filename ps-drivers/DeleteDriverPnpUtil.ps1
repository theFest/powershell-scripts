Function DeleteDriverPnpUtil {
    <#
    .SYNOPSIS
    Deletes a driver using PnPUtil on the local or remote machine.

    .DESCRIPTION
    This function deletes a driver on the local or remote machine using the PnPUtil utility.
    Supports uninstalling the driver, using force for the deletion, and can optionally reboot the system after deletion.

    .PARAMETER DriverInfFile
    Mandatory - path to the driver INF file that needs to be deleted.
    .PARAMETER ComputerName
    NotMandatory - name of the remote computer where you want to delete the driver. If not provided, the driver will be deleted on the local machine.
    .PARAMETER Username
    NotMandatory - username used for authentication when connecting to the remote machine. Required if the ComputerName parameter is specified.
    .PARAMETER Pass
    NotMandatory - password for the specified username. Required if the ComputerName parameter is specified.
    .PARAMETER Uninstall
    NotMandatory - whether to uninstall the driver. If not specified, only the driver files will be deleted.
    .PARAMETER Force
    NotMandatory - indicate whether to force the deletion of the driver.
    .PARAMETER Reboot
    NotMandatory - indicate whether to reboot the machine after driver deletion.

    .EXAMPLE
    DeleteDriverPnpUtil -ComputerName "remote_hostname" -Username "remote_user" -Pass "remote_pass" -DriverInfFile "C:\Windows\INF\oem26.inf" -Uninstall -Force -Reboot -Verbose

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$DriverInfFile,

        [Parameter(Mandatory = $false)]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false)]
        [string]$Username,

        [Parameter(Mandatory = $false)]
        [string]$Pass,

        [Parameter(Mandatory = $false)]
        [switch]$Uninstall,

        [Parameter(Mandatory = $false)]
        [switch]$Force,

        [Parameter(Mandatory = $false)]
        [switch]$Reboot
    )
    $SecurePassword = $null
    if ($Pass) {
        $SecurePassword = ConvertTo-SecureString $Pass -AsPlainText -Force
    }
    $Credential = $null
    if ($ComputerName -ne $env:COMPUTERNAME) {
        Write-Verbose -Message "Testing connection to remote computer $ComputerName..."
        if (-not (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)) {
            Write-Error "Unable to connect to the remote computer $ComputerName. Please check the computer name or network connectivity." -ForegroundColor Red
            return
        }
        Write-Verbose -Message "Testing WSMan connection to remote computer $ComputerName..."
        if (-not (Test-WSMan -ComputerName $ComputerName -ErrorAction SilentlyContinue)) {
            Write-Error "Unable to establish a WSMan connection to the remote computer $ComputerName. Make sure WSMan is properly configured on the remote machine." -ForegroundColor Red
            return
        }
        $Credential = New-Object System.Management.Automation.PSCredential ($Username, $SecurePassword)
    }
    Write-Verbose -Message "Checking if pnputil.exe is in the environment variables and add it if not found"
    if (-not (Get-Command -Name "pnputil" -ErrorAction SilentlyContinue)) {
        Write-Warning "pnputil.exe not found in the environment variables. Adding it to the PATH..." -ForegroundColor Yellow
        $env:Path += ";$($env:SystemRoot)\System32"
    }
    $PnpUtilCommand = "pnputil.exe"
    $Arguments = "/delete-driver $DriverInfFile"
    if ($Uninstall) {
        $Arguments += " /uninstall" 
    }
    if ($Force) { 
        $Arguments += " /force" 
    }
    if ($Reboot) { 
        $Arguments += " /reboot" 
    }
    if ($ComputerName -eq $env:COMPUTERNAME) {
        Write-Verbose -Message "Executing on the local machine: $PnpUtilCommand $Arguments"
        try {
            Start-Process -FilePath $PnpUtilCommand -ArgumentList $Arguments -Wait -NoNewWindow -ErrorAction Stop
            Write-Output "Driver deletion on the local machine completed successfully."
        }
        catch {
            Write-Error "Failed to delete driver on the local machine: $_" -ForegroundColor Red
        }
    }
    else {
        Write-Verbose -Message "Executing on remote machine $ComputerName..."
        try {
            Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock {
                param ($PnpUtilCommand, $Arguments)
                Start-Process -FilePath $PnpUtilCommand -ArgumentList $Arguments -Wait -NoNewWindow -ErrorAction Stop
            } -ArgumentList $PnpUtilCommand, $Arguments
            Write-Output "Driver deletion on remote machine $ComputerName completed successfully."
        }
        catch {
            Write-Error "Failed to delete driver on remote machine $ComputerName : $_" -ForegroundColor Red
        }
    }
}
