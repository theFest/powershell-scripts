Function ExportDriversPnpUtil {
    <#
    .SYNOPSIS
    Export driver package(s) from the driver store into a target directory using PnPUtil.

    .DESCRIPTION
    This function exports driver package(s) from the driver store into a specified target directory using PnPUtil. The target directory will be created if it does not exist.

    .PARAMETER DriverName
    Mandatory - The name of the driver package to export. Use "*" to export all driver packages.
    .PARAMETER TargetDirectory
    Mandatory - The directory where the driver package(s) will be exported.
    .PARAMETER ComputerName
    NotMandatory - name of the remote computer from which to export the driver packages. If not provided, the function will run on the local machine.
    .PARAMETER Username
    NotMandatory - username used for authentication when connecting to the remote machine. Required if the ComputerName parameter is specified.
    .PARAMETER Pass
    NotMandatory - password for the specified username. Required if the ComputerName parameter is specified.
    .PARAMETER CopyToLocalMachine
    NotMandatory - if provided, the exported driver packages will be copied to the local machine after exporting.

    .EXAMPLE
    ExportDriversPnpUtil -DriverName "oem12.inf" -TargetDirectory "$env:USERPROFILE\Desktop\Driver" -Verbose
    ExportDriversPnpUtil -DriverName "*" -TargetDirectory "C:\remote_host\targer_folder" -ComputerName "remote_hostname" -Username "remote_user" -Pass "remote_pass"

    .NOTES
    v0.0.3
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$DriverName,

        [Parameter(Mandatory = $true)]
        [string]$TargetDirectory,

        [Parameter(Mandatory = $false)]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false)]
        [string]$Username,

        [Parameter(Mandatory = $false)]
        [string]$Pass,

        [Parameter(Mandatory = $false)]
        [switch]$CopyToLocalMachine
    )
    if ($ComputerName -ne $env:COMPUTERNAME) {
        Write-Verbose -Message "Testing connection to remote computer $ComputerName..."
        if (-not (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)) {
            Write-Error "Unable to connect to the remote computer $ComputerName. Please check the computer name or network connectivity." -ForegroundColor Red
            return
        }
        Write-Verbose -Message "Creating remote session to $ComputerName..."
        $SecurePassword = ConvertTo-SecureString $Pass -AsPlainText -Force
        $Credential = New-Object System.Management.Automation.PSCredential ($Username, $SecurePassword)
        $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential
        if (!$Session) {
            Write-Error "Unable to establish a remote session to the computer $ComputerName. Please check the credentials or the remote configuration."
            return
        }
        try {
            Write-Verbose -Message "Exporting driver package(s) from remote machine $ComputerName..."
            Invoke-Command -Session $Session -ScriptBlock {
                param ($PnpUtilCommand, $DriverName, $TargetDirectory)
                Write-Verbose -Message "Checking if pnputil.exe is in the environment variables and add it if not found"
                if (-not (Get-Command -Name "pnputil" -ErrorAction SilentlyContinue)) {
                    Write-Host "Adding pnputil.exe to the environment variables..." -ForegroundColor DarkGreen
                    $env:Path += ";$($env:SystemRoot)\System32"
                }
                Write-Verbose -Message "Checking if the target directory exists..."
                if (-not (Test-Path -Path $TargetDirectory -PathType Container)) {
                    Write-Host "Creating target directory: $TargetDirectory" -ForegroundColor DarkGreen
                    New-Item -Path $TargetDirectory -ItemType Directory | Out-Null
                }
                Write-Verbose -Message "Exporting the driver package(s) using PnPUtil"
                $PnpUtilCommand = "pnputil.exe /export-driver $DriverName '$TargetDirectory'"
                Invoke-Expression -Command $PnpUtilCommand
                Write-Host "Driver package(s) exported successfully to: $TargetDirectory" -ForegroundColor Green
            } -ArgumentList $PnpUtilCommand, $DriverName, $TargetDirectory
        }
        finally {
            Write-Verbose "Closing the remote session to $ComputerName..."
            Remove-PSSession -Session $Session
        }
    }
    else {
        Write-Verbose -Message "Checking if pnputil.exe is in the environment variables and add it if not found"
        if (-not (Get-Command -Name "pnputil" -ErrorAction SilentlyContinue)) {
            Write-Host "Adding pnputil.exe to the environment variables..." -ForegroundColor DarkGreen
            $env:Path += ";$($env:SystemRoot)\System32"
        }
        Write-Verbose -Message "Checking if the target directory exists..."
        if (-not (Test-Path -Path $TargetDirectory -PathType Container)) {
            Write-Host "Creating target directory: $TargetDirectory" -ForegroundColor DarkGreen
            New-Item -Path $TargetDirectory -ItemType Directory | Out-Null
        }
        Write-Verbose -Message "Exporting the driver package(s) using PnPUtil"
        $PnpUtilCommand = "pnputil.exe /export-driver $DriverName '$TargetDirectory'"
        Invoke-Expression -Command $PnpUtilCommand
        Write-Host "Driver package(s) exported successfully to: $TargetDirectory" -ForegroundColor Green
    }
    if ($CopyToLocalMachine -and $ComputerName -ne $env:COMPUTERNAME) {
        Write-Verbose -Message "Copying exported driver packages from $ComputerName to the local machine..."
        $ZipFileName = "$TargetDirectory\DriverPackages.zip"
        $LocalCopyPath = Join-Path -Path $env:TEMP -ChildPath "DriverPackages"
        Compress-Archive -Path "$TargetDirectory\*" -DestinationPath $ZipFileName -Force
        New-Item -Path $LocalCopyPath -ItemType Directory | Out-Null
        Copy-Item -Path $ZipFileName -Destination $LocalCopyPath -Force
        Write-Host "Driver packages copied from $ComputerName to: $LocalCopyPath" -ForegroundColor Green
    }
}