Function Export-DriverWithPnPUtil {
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
    .PARAMETER CompressZip
    NotMandatory - if provided, the exported driver packages will be compressed into a ZIP file.
    .PARAMETER LocalCopyPath
    NotMandatory - path to the directory where the exported driver packages will be copied on the local machine.

    .EXAMPLE
    Export-DriverWithPnPUtil -DriverName "oem12.inf" -TargetDirectory "$env:USERPROFILE\Desktop\Driver" -Verbose
    Export-DriverWithPnPUtil -DriverName "*" -TargetDirectory "C:\remote_host\targer_folder" -ComputerName "remote_hostname" -Username "remote_user" -Pass "remote_pass"

    .NOTES
    v0.0.6
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
        [switch]$CopyToLocalMachine,
    
        [Parameter(Mandatory = $false)]
        [switch]$CompressZip,
    
        [Parameter(Mandatory = $false)]
        [string]$LocalCopyPath = $env:TEMP
    )
    if ($ComputerName -ne $env:COMPUTERNAME) {
        Write-Verbose -Message "Testing connection to remote computer $ComputerName..."
        if (-not (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)) {
            Write-Error "Unable to connect to the remote computer $ComputerName. Please check the computer name or network connectivity."
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
    if ($CompressZip) {
        if (Test-Path $TargetDirectory) {
            $ZipFileName = Join-Path -Path $TargetDirectory -ChildPath "DriverPackages.zip"
            Compress-Archive -Path "$TargetDirectory\*" -DestinationPath $ZipFileName -Force
            Write-Host "Driver packages compressed to: $ZipFileName" -ForegroundColor Green
        }
        else {
            Write-Warning "The specified target directory '$TargetDirectory' does not exist. Cannot create the ZIP file."
        }
    }
    if ($CopyToLocalMachine -and $ComputerName -ne $env:COMPUTERNAME) {
        Write-Verbose -Message "Copying exported driver packages from $ComputerName to the local machine..."
        if (-not (Test-Path $LocalCopyPath -PathType Container)) {
            Write-Host "Creating local copy directory: $LocalCopyPath" -ForegroundColor DarkGreen
            New-Item -Path $LocalCopyPath -ItemType Directory | Out-Null
        }
        if (Test-Path $ZipFileName) {
            Copy-Item -Path $ZipFileName -Destination $LocalCopyPath -Force
            Write-Host "Driver packages copied from $ComputerName to: $LocalCopyPath" -ForegroundColor Green
        }
        else {
            Write-Warning "The ZIP file '$ZipFileName' does not exist on the remote machine. Cannot copy the driver packages."
        }
    }
}
