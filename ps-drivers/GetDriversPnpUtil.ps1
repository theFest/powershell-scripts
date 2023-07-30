Function GetDriversPnpUtil {
    <#
    .SYNOPSIS
    Retrieves the list of installed drivers on the local or remote computer using PnPUtil.

    .DESCRIPTION
    This function retrieves the list of installed drivers on the local machine or a remote computer
    using PnPUtil and optionally includes Microsoft drivers in the output. The function can export the result to a CSV file.

    .PARAMETER ComputerName
    NotMandatory - name of the remote computer from which to retrieve the driver information. Default is the local computer.
    .PARAMETER Username
    NotMandatory - username to be used for connecting to the remote computer (if applicable).
    .PARAMETER Password
    NotMandatory - password for the provided username (if applicable).
    .PARAMETER IncludeMicrosoftDrivers
    NotMandatory - switch parameter to include Microsoft drivers in the output.
    .PARAMETER CsvPath
    NotMandatory - the path of the CSV file to which the driver information will be exported.

    .EXAMPLE
    GetDriversPnpUtil -IncludeMicrosoftDrivers -Verbose
    GetDriversPnpUtil -CsvPath "$env:USERPROFILE\Desktop\DriverList.csv"
    "remote_computer" | GetDriversPnpUtil -Username "remote_user" -Pass "remote_pass" -IncludeMicrosoftDrivers -Verbose
    "remote_computer" | GetDriversPnpUtil -Username "remote_user" -Pass "remote_pass" -CsvPath "$env:USERPROFILE\Desktop\DriverList.csv"

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
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeMicrosoftDrivers,
        
        [Parameter(Mandatory = $false)]
        [string]$CsvPath
    )
    if ($ComputerName -ne $env:COMPUTERNAME) {
        Write-Verbose -Message "Testing connection to remote computer $ComputerName..."
        if (-not (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)) {
            Write-Error -Message "Unable to connect to the remote computer $ComputerName. Please check the computer name or network connectivity." -ForegroundColor Red
            return
        }
        Write-Verbose -Message "Testing WSMan connection to remote computer $ComputerName..."
        if (-not (Test-WSMan -ComputerName $ComputerName -ErrorAction SilentlyContinue)) {
            Write-Error -Message "Unable to establish a WSMan connection to the remote computer $ComputerName. Make sure WSMan is properly configured on the remote machine."
            return
        }
    }
    Write-Verbose -Message "Checking if pnputil.exe is in the environment variables and add it if not found"
    if (-not (Get-Command -Name "pnputil" -ErrorAction SilentlyContinue)) {
        Write-Host "Adding pnputil.exe to the environment variables..." -ForegroundColor DarkGreen
        $env:Path += ";$($env:SystemRoot)\System32"
    }
    if ($ComputerName -eq $env:COMPUTERNAME) {
        Write-Host "Getting installed drivers on the local machine..." -ForegroundColor Cyan
        $PnpUtilCommand = "pnputil.exe /enum-drivers"
        $result = Invoke-Expression -Command $PnpUtilCommand
    }
    else {
        Write-Host "Getting installed drivers on remote machine $ComputerName..." -ForegroundColor Cyan
        $SecurePassword = ConvertTo-SecureString $Pass -AsPlainText -Force
        $Credential = New-Object System.Management.Automation.PSCredential ($Username, $SecurePassword)
        $PnpUtilCommand = "pnputil.exe /enum-drivers"
        $Result = Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock {
            param ($PnpUtilCommand)
            Invoke-Expression -Command $PnpUtilCommand
        } -ArgumentList $PnpUtilCommand
    }
    if ($IncludeMicrosoftDrivers) {
        if ($ComputerName -eq $env:COMPUTERNAME) {
            Write-Host "Including Microsoft drivers on the local machine..." -ForegroundColor Yellow
            $MsDrivers = Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.Manufacturer -eq "Microsoft" } `
            | Select-Object DeviceName, CompatID, Description, DeviceID, DriverProviderName, DriverVersion, HardWareID, InfName, IsSigned, Manufacturer, PDO, Signer 
            $Result += $MsDrivers | Format-Table -AutoSize | Out-String
        }
        else {
            Write-Host "Including Microsoft drivers on remote machine $ComputerName..." -ForegroundColor Yellow
            $MsDrivers = Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock {
                Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.Manufacturer -eq "Microsoft" }
            }
            $MsDrivers = $MsDrivers | Select-Object DeviceName, CompatID, Description, DeviceID, DriverProviderName, DriverVersion, HardWareID, InfName, IsSigned, Manufacturer, PDO, Signer
            $Result += $MsDrivers | Format-Table -AutoSize | Out-String
        }
    }
    if ($CsvPath) {
        Write-Verbose -Message "Exporting installed drivers to CSV: $CsvPath"
        $Result | Out-File -FilePath $CsvPath -Encoding UTF8
    }
    return $Result
}
