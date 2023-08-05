Function AddDriversPnpUtil {
    <#
    .SYNOPSIS
    Installs drivers using PnPUtil on the local or remote machine.

    .DESCRIPTION
    This function installs drivers on the local or remote machine using the PnPUtil utility, supports installing drivers from subdirectories, and can optionally reboot the system after installation.
    It copies the driver files from the specified source folder to the target machine (if remote) and performs a bulk installation of driver packages.

    .PARAMETER ComputerName
    Mandatory - name of the remote computer where you want to install the drivers. If not provided, the drivers will be installed on the local machine.
    .PARAMETER Username
    Mandatory - username used for authentication when connecting to the remote machine. Required if the ComputerName parameter is specified.
    .PARAMETER Pass
    Mandatory - password for the specified username. Required if the ComputerName parameter is specified.
    .PARAMETER DriverPath
    Mandatory - path to the folder containing the driver files (INF files) that need to be installed.
    .PARAMETER Subdirs
    NotMandatory - whether to include subdirectories when searching for driver INF files in the DriverPath.
    .PARAMETER Install
    NotMandatory - to actually perform the installation of the drivers. If not specified, it only validates the existence of the driver folder and driver files.
    .PARAMETER Reboot
    NotMandatory - switch to indicate whether to reboot the machine after driver installation.

    .EXAMPLE
    AddDriversPnpUtil -ComputerName "remote_hostname" -Username "remote_user" -Pass "remote_pass" -DriverPath "C:\drivers_folder_path" -Install -Subdirs -Reboot -Verbose

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false)]
        [string]$Username,

        [Parameter(Mandatory = $false)]
        [string]$Pass,

        [Parameter(Mandatory = $true)]
        [string]$DriverPath,

        [Parameter(Mandatory = $false)]
        [switch]$Subdirs,

        [Parameter(Mandatory = $false)]
        [switch]$Install,

        [Parameter(Mandatory = $false)]
        [switch]$Reboot
    )
    Write-Verbose -Message "Validating the existence of the driver folder..."
    if (-not (Test-Path $DriverPath -PathType Container)) {
        Write-Error -Message "Driver folder not found at '$DriverPath'. Please provide a valid path."
        return
    }
    $DriverFiles = Get-ChildItem $DriverPath -Recurse -Filter "*.inf" -File
    if ($DriverFiles.Count -eq 0) {
        Write-Warning "No driver files found in the specified folder."
        return
    }
    $Session = $null
    if ($ComputerName -ne $env:COMPUTERNAME) {
        Write-Verbose "Testing connection to remote computer $ComputerName..."
        if (-not (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)) {
            Write-Error -Message "Unable to connect to the remote computer $ComputerName. Please check the computer name or network connectivity."
            return
        }
        Write-Verbose -Message "Creating remote session to $ComputerName..."
        $SecurePassword = ConvertTo-SecureString $Pass -AsPlainText -Force
        $Credential = New-Object System.Management.Automation.PSCredential ($Username, $SecurePassword)
        $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential
        if (!$Session) {
            Write-Error -Message "Unable to establish a remote session to the computer $ComputerName. Please check the credentials or the remote configuration."
            return
        }
    }
    try {
        if ($Session) {
            Write-Verbose -Message "Copying driver files to remote machine..."
            Copy-Item -Path $DriverPath -Destination "C:\Temp\" -Recurse -Container -ToSession $Session
            $RemoteDriverPath = "C:\Temp\" + (Get-Item $DriverPath).Name
        }
        else {
            $RemoteDriverPath = $DriverPath
        }
        Write-Verbose -Message "Performing bulk installation of driver packages..."
        $PnpUtilCommand = "pnputil.exe"
        $Arguments = "/add-driver `"$RemoteDriverPath\*.inf`""
        if ($Subdirs) {
            $Arguments += " /subdirs"
        }
        if ($Install) {
            $Arguments += " /install"
        }
        if ($Reboot) {
            $Arguments += " /reboot"
        }
        if ($Session) {
            Write-Host "Adding driver packages on remote machine $ComputerName..." -ForegroundColor Cyan
            Invoke-Command -Session $Session -ScriptBlock {
                param ($PnpUtilCommand, $Arguments)
                Start-Process -FilePath $PnpUtilCommand -ArgumentList $Arguments -Wait -NoNewWindow
            } -ArgumentList $PnpUtilCommand, $Arguments
        }
        else {
            Write-Host "Adding driver packages on the local machine..." -ForegroundColor Cyan
            Start-Process -FilePath $PnpUtilCommand -ArgumentList $Arguments -Wait -NoNewWindow
        }
    }
    finally {
        if ($Session) {
            Write-Verbose -Message "Closing the remote session to $ComputerName..."
            Remove-PSSession -Session $Session
        }
    }
}