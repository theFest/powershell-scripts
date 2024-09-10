function Use-HostsEditor {
    <#
    .SYNOPSIS
    Manages hostnames in the hosts file using the BlueLife Hosts Editor tool.

    .DESCRIPTION
    This function downloads and executes BlueLife Hosts Editor to manage hostnames in the hosts file, including blocking, deleting, backing up, and restoring. Credits to Sordum.

    .EXAMPLE
    Use-HostsEditor -HostsOperation '/A' -HostNames 'www.example.com,example.com,www.example-2.com'
    Use-HostsEditor -HostsOperation '/D' -HostNames 'www.example.com,example.com,www.example-2.com' -StartApplication

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Specify the operation to perform on the hosts file")]
        [ValidateSet("/A", "/D", "/B", "/R", "/SR", "/SW")]
        [string]$HostsOperation,

        [Parameter(Mandatory = $false, HelpMessage = "Hostnames to manage, comma-separated (e.g., 'www.example.com,example.com,www.example-2.com')")]
        [string]$HostNames = "",

        [Parameter(Mandatory = $false, HelpMessage = "IP address to associate with hostnames for blocking (default: 0.0.0.0)")]
        [string]$IpAddress = "0.0.0.0",

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading the BlueLife Hosts Editor tool")]
        [uri]$HostsEditorDownloadUrl = "https://www.sordum.org/files/download/host-editor/HostsEditor.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where the BlueLife Hosts Editor tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\BlueLifeHostsEditor",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveHostsEditor,

        [Parameter(Mandatory = $false, HelpMessage = "Start the BlueLife Hosts Editor application after extraction")]
        [switch]$StartApplication
    )
    $HostsEditorZipPath = Join-Path $DownloadPath "HostsEditor.zip"
    $HostsEditorExtractPath = Join-Path $DownloadPath "BlueLifeHostsEditor"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        if (!(Test-Path -Path $HostsEditorZipPath)) {
            Write-Host "Downloading BlueLife Hosts Editor tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri $HostsEditorDownloadUrl -OutFile $HostsEditorZipPath -UseBasicParsing -Verbose
            if ((Get-Item $HostsEditorZipPath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt."
            }
        }
        Write-Host "Extracting BlueLife Hosts Editor tool..." -ForegroundColor Green
        if (Test-Path -Path $HostsEditorExtractPath) {
            Remove-Item -Path $HostsEditorExtractPath -Recurse -Force
        }
        try {
            [System.IO.Compression.ZipFile]::ExtractToDirectory($HostsEditorZipPath, $HostsEditorExtractPath)
        }
        catch {
            throw "Failed to extract the ZIP file. It may be corrupt or incomplete."
        }
        $HostsEditorExecutable = Get-ChildItem -Path $HostsEditorExtractPath -Recurse -Filter "hEdit_x64.exe" | Select-Object -First 1
        if (-Not $HostsEditorExecutable) {
            throw "hEdit_x64.exe not found in $HostsEditorExtractPath"
        }
        $Arguments = if ($HostNames) {
            if ($HostsOperation -eq "/A") {
                "$HostsOperation $HostNames $IpAddress"
            }
            else {
                "$HostsOperation $HostNames"
            }
        }
        else {
            $HostsOperation
        }
        Write-Verbose -Message "Starting BlueLife Hosts Editor with arguments: $Arguments"
        if ($StartApplication) {
            Start-Process -FilePath $HostsEditorExecutable.FullName
        }
        else {
            Start-Process -FilePath $HostsEditorExecutable.FullName -ArgumentList $Arguments -WindowStyle Hidden -Wait
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "Hosts operation '$HostsOperation' completed." -ForegroundColor Cyan
        if ($RemoveHostsEditor) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
