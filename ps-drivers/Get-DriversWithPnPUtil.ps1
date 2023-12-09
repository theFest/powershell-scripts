Function Get-DriversWithPnPUtil {
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
    .PARAMETER Pass
    NotMandatory - password for the provided username (if applicable).
    .PARAMETER IncludeMicrosoftDrivers
    NotMandatory - switch parameter to include Microsoft drivers in the output.
    .PARAMETER CsvPath
    NotMandatory - the path of the CSV file to which the driver information will be exported.

    .EXAMPLE
    Get-DriversWithPnPUtil -IncludeMicrosoftDrivers -Verbose
    Get-DriversWithPnPUtil -CsvPath "$env:USERPROFILE\Desktop\DriverList.csv"
    "remote_computer" | Get-DriversWithPnPUtil -Username "remote_user" -Pass "remote_pass" -IncludeMicrosoftDrivers -Verbose
    "remote_computer" | Get-DriversWithPnPUtil -Username "remote_user" -Pass "remote_pass" -CsvPath "$env:USERPROFILE\Desktop\DriverList.csv"

    .NOTES
    v0.0.3
    #>
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, ValueFromPipeline = $true, HelpMessage = "The name of the remote computer to retrieve drivers from")]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Position = 1, HelpMessage = "Username for authentication (if required)")]
        [string]$Username,

        [Parameter(Position = 2, HelpMessage = "Password for authentication (if required)")]
        [string]$Pass,

        [Parameter(HelpMessage = "Include Microsoft drivers in the result")]
        [switch]$IncludeMicrosoftDrivers,

        [Parameter(HelpMessage = "The path to export the drivers list to a CSV file")]
        [string]$CsvPath
    )
    if ($ComputerName -ne $env:COMPUTERNAME) {
        Write-Verbose "Testing connection to remote computer $ComputerName..."
        if (-not (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)) {
            Write-Error "Unable to connect to the remote computer $ComputerName. Please check the computer name or network connectivity." -ForegroundColor Red
            return
        }
        Write-Verbose "Testing WSMan connection to remote computer $ComputerName..."
        if (-not (Test-WSMan -ComputerName $ComputerName -ErrorAction SilentlyContinue)) {
            Write-Error "Unable to establish a WSMan connection to the remote computer $ComputerName. Make sure WSMan is properly configured on the remote machine."
            return
        }
    }
    if ($ComputerName -eq $env:COMPUTERNAME) {
        Write-Host "Getting installed drivers from the local machine..." -ForegroundColor Cyan
        $Drivers = Get-CimInstance -Class Win32_PnPSignedDriver
    }
    else {
        Write-Host "Getting installed drivers on remote machine $ComputerName..." -ForegroundColor Cyan
        $SecurePassword = ConvertTo-SecureString $Pass -AsPlainText -Force
        $Credential = New-Object System.Management.Automation.PSCredential ($Username, $SecurePassword)
        $Drivers = Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock {
            Get-CimInstance -Class Win32_PnPSignedDriver
        }
    }
    if ($IncludeMicrosoftDrivers) {
        $MsDrivers = $Drivers | Where-Object { $_.Manufacturer -eq "Microsoft" }
        $Result = $MsDrivers | Select-Object `
            DeviceName, CompatID, Description, DeviceID, DriverProviderName, DriverVersion, HardWareID, InfName, IsSigned, Manufacturer, PDO, Signer
    }
    else {
        $Result = $Drivers | Select-Object `
            DeviceName, CompatID, Description, DeviceID, DriverProviderName, DriverVersion, HardWareID, InfName, IsSigned, Manufacturer, PDO, Signer
    }
    if ($CsvPath) {
        Write-Verbose "Exporting installed drivers to CSV: $CsvPath"
        $Result | Export-Csv -Path $CsvPath -NoTypeInformation
    }
    return $Result
}
