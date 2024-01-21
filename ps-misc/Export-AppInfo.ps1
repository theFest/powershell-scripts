Function Export-AppInfo {
    <#
    .SYNOPSIS
    Exports information about applications based on the specified criteria, including filtering by AppName and exporting results to CSV.

    .DESCRIPTION
    This function retrieves information about applications, allowing you to filter results by AppName and export the data to a CSV file, supports remote execution on a specified computer.

    .PARAMETER FilterAppName
    Application Name to filter the results, only applications matching the specified AppName will be included in the output.
    .PARAMETER RemoteExportPath
    Path on the remote machine where the CSV file will be exported. If the path does not exist, the function creates it.
    .PARAMETER ExportFileName
    Specifies the name of the CSV file when exporting, default value is "AppInfo.csv".
    .PARAMETER ComputerName
    Remote computer hostname where the function will execute, if not provided, the function runs locally.
    .PARAMETER User
    Specifies the username for the remote session if required.
    .PARAMETER Pass
    Specifies the password for the remote session if required.
    .PARAMETER LocalCopyPath
    Specifies the path on the local machine where the exported CSV file will be copied, if not provided, no local copy will be made.

    .EXAMPLE
    Export-AppInfo -RemoteExportPath "C:\Temp" -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass" -LocalCopyPath "$env:USERPROFILE\Desktop"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0, HelpMessage = "Filter by AppName")]
        [string]$FilterAppName,

        [Parameter(Mandatory = $true, Position = 1, HelpMessage = "Path to export the results as CSV on the remote machine")]
        [string]$RemoteExportPath,

        [Parameter(Mandatory = $false, Position = 2, HelpMessage = "Name of CSV file when exporting")]
        [string]$ExportFileName = "AppInfo.csv",

        [Parameter(Mandatory = $false, Position = 3, HelpMessage = "Specify a remote computer")]
        [string]$ComputerName,

        [Parameter(Mandatory = $false, Position = 4, HelpMessage = "Username for remote session")]
        [string]$User,

        [Parameter(Mandatory = $false, Position = 5, HelpMessage = "Password for remote session")]
        [string]$Pass,

        [Parameter(Mandatory = $false, Position = 6, HelpMessage = "Path to copy the results on the local machine")]
        [string]$LocalCopyPath = "$env:USERPROFILE\Desktop"
    )
    try {
        $SessionParams = @{ ErrorAction = 'Stop' }
        if ($ComputerName) {
            $Cred = $null
            if ($User -and $Pass) {
                $SecPass = ConvertTo-SecureString -String $Pass -AsPlainText -Force
                $Cred = New-Object System.Management.Automation.PSCredential -ArgumentList $User, $SecPass
            }
            $RemoteExportPathExists = Invoke-Command -ComputerName $ComputerName -Credential $Cred -ScriptBlock {
                param($Path)
                Test-Path -Path $Path -PathType Container
            } -ArgumentList $RemoteExportPath @SessionParams
            if (-not $RemoteExportPathExists) {
                Invoke-Command -ComputerName $ComputerName -Credential $Cred -ScriptBlock {
                    param($Path)
                    New-Item -Path $Path -ItemType Directory -Force
                } -ArgumentList $RemoteExportPath @SessionParams
            }
            $Apps = Invoke-Command -ComputerName $ComputerName -Credential $Cred -ScriptBlock {
                param($FilterAppName)
                $Apps = Get-StartApps
                if ($FilterAppName) {
                    $Apps = $Apps | Where-Object { $_.AppId -like "*$FilterAppName*" }
                }
                return $Apps
            } -ArgumentList $FilterAppName @SessionParams
            if ($RemoteExportPath) {
                $RemoteExportFilePath = Join-Path -Path $RemoteExportPath -ChildPath $ExportFileName
                $Apps | Export-Csv -Path $RemoteExportFilePath -NoTypeInformation
                Write-Host "Results exported to $RemoteExportFilePath on remote machine" -ForegroundColor Green
                if ($LocalCopyPath) {
                    $LocalCopyFilePath = Join-Path -Path $LocalCopyPath -ChildPath $ExportFileName
                    Copy-Item -Path $RemoteExportFilePath -Destination $LocalCopyFilePath
                    Write-Host "Results copied to $LocalCopyFilePath on local machine" -ForegroundColor Green
                }
            }
            return $Apps
        }
        else {
            $Apps = Get-StartApps
            if ($FilterAppName) {
                $Apps = $Apps | Where-Object { $_.AppId -like "*$FilterAppName*" }
            }
            $AppUserModelIDs = $Apps | ForEach-Object {
                [PSCustomObject]@{
                    AppName        = $_.AppId
                    AppUserModelId = $_.AppUserModelId
                }
            }
            Write-Output -InputObject $AppUserModelIDs
            if ($RemoteExportPath) {
                if (-not (Test-Path -Path $RemoteExportPath -PathType Container)) {
                    New-Item -Path $RemoteExportPath -ItemType Directory -Force
                }
                $ExportPath = Join-Path -Path $RemoteExportPath -ChildPath $ExportFileName
                $AppUserModelIDs | Export-Csv -Path $ExportPath -NoTypeInformation
                Write-Host "Results exported to $ExportPath" -ForegroundColor Green
            }
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
}
