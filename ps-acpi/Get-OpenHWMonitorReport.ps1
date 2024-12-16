function Get-OpenHWMonitorReport {
    <#
    .SYNOPSIS
    Generates a hardware monitoring report using Open Hardware Monitor on a local or remote computer.

    .DESCRIPTION
    Automates the process of generating a hardware monitoring report using the Open Hardware Monitor tool. It downloads the necessary executable, extracts it to a temporary directory, and runs the tool to generate the report.
    The report can be generated locally or on a remote machine. If running remotely, the function supports authentication using provided credentials.

    .EXAMPLE
    Get-OpenHWMonitorReport -OutputFilePath "C:\Reports\HardwareReport.txt"
    Get-OpenHWMonitorReport -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass" -OutputFilePath "C:\Reports\RemoteHardwareReport.txt"

    .NOTES
    v0.1.1

    .LINK
    https://github.com/openhardwaremonitor
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Output file path")]
        [string]$OutputFilePath,

        [Parameter(Mandatory = $false, HelpMessage = "URL to download OpenHardwareMonitorReport")]
        [string]$Url = "https://github.com/openhardwaremonitor/openhardwaremonitor/files/1130239/OpenHardwareMonitorReport.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Temporary folder for extraction")]
        [string]$TempFolder = "$env:TEMP\OpenHardwareMonitorReport",

        [Parameter(Mandatory = $false, HelpMessage = "Remote computer name")]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false, HelpMessage = "Username for remote computer")]
        [string]$User,

        [Parameter(Mandatory = $false, HelpMessage = "Password for remote computer")]
        [string]$Pass
    )
    try {
        $Credential = if ($User -and $Pass) {
            $SecurePassword = ConvertTo-SecureString $Pass -AsPlainText -Force
            New-Object System.Management.Automation.PSCredential ($User, $SecurePassword)
        }
        else {
            $null
        }
        $ScriptBlock = {
            param ($Url, $TempFolder, $OutputFilePath)
            try {
                if (Test-Path -Path $TempFolder) {
                    Remove-Item -Path $TempFolder -Recurse -Force
                }
                New-Item -Path $TempFolder -ItemType Directory -Force | Out-Null
                $ZipFilePath = Join-Path -Path $env:TEMP -ChildPath "OpenHardwareMonitorReport.zip"
                Invoke-WebRequest -Uri $Url -OutFile $ZipFilePath -ErrorAction Stop
                Expand-Archive -Path $ZipFilePath -DestinationPath $TempFolder -Force
                $Executable = Join-Path -Path $TempFolder -ChildPath "OpenHardwareMonitorReport.exe"
                if (-Not (Test-Path -Path $Executable)) {
                    throw "Executable not found: $Executable"
                }
                $CmdOutput = cmd /c "cd /d $TempFolder && $Executable"
                $ReportPath = Join-Path -Path $TempFolder -ChildPath "output.txt"
                $CmdOutput | Out-File -FilePath $ReportPath -Force
                if (-Not (Test-Path -Path $ReportPath -PathType Leaf)) {
                    throw "Failed to generate output file!"
                }
                $OutputDirectory = [System.IO.Path]::GetDirectoryName($OutputFilePath)
                if (-Not (Test-Path -Path $OutputDirectory)) {
                    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
                }
                Move-Item -Path $ReportPath -Destination $OutputFilePath -Force
                Write-Output "Hardware information has been successfully saved to $OutputFilePath"
            }
            catch {
                throw "Error during execution: $_"
            }
        }
        if ($ComputerName -ne $env:COMPUTERNAME) {
            Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock $ScriptBlock -ArgumentList $Url, $TempFolder, $OutputFilePath
        }
        else {
            & $ScriptBlock.Invoke($Url, $TempFolder, $OutputFilePath)
        }
    }
    catch {
        Write-Error -Message "Failed to fetch hardware information: $_"
    }
    finally {
        Write-Verbose -Message "Cleaning up temporary files..."
        if (Test-Path -Path $TempFolder) {
            Remove-Item -Path $TempFolder -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
