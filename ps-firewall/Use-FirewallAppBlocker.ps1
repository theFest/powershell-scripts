function Use-FirewallAppBlocker {
    <#
    .SYNOPSIS
    Manages firewall rules using the Firewall App Blocker tool.

    .DESCRIPTION
    This function downloads and executes Firewall App Blocker to manage firewall rules, including adding, deleting, enabling, or disabling rules. Credits to Sordum.

    .EXAMPLE
    Use-FirewallAppBlocker -Command '/A' -FilePath 'C:\ExampleApp.exe'
    Use-FirewallAppBlocker -Command '/D /In' -FilePath 'C:\ExampleApp.exe'
    Use-FirewallAppBlocker -Command '/ER' -FilePath 'TargetRuleName' -StartApplication
    Use-FirewallAppBlocker -Command '/O 1'
    
    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Specify the command to execute with Firewall App Blocker")]
        [ValidateSet('/A', '/D', '/Out', '/In', '/Block', '/Allow', '/ER', '/DR', '/I', '/O')]
        [string]$Command,

        [Parameter(Mandatory = $false, HelpMessage = "File path or folder path for the rule")]
        [string]$FilePath = "",

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading the Firewall App Blocker tool")]
        [uri]$FabDownloadUrl = "https://www.sordum.org/files/download/firewall-app-blocker/fab.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where the Firewall App Blocker tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\FirewallAppBlocker",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFirewallAppBlocker,

        [Parameter(Mandatory = $false, HelpMessage = "Start the Firewall App Blocker application after extraction")]
        [switch]$StartApplication
    )
    if ($Command -in @('/A', '/D', '/ER', '/DR', '/I') -and -not $FilePath) {
        throw "FilePath must be provided when Command is '/A', '/D', '/ER', '/DR', or '/I'."
    }
    $FabZipPath = Join-Path $DownloadPath "fab.zip"
    $FabExtractPath = Join-Path $DownloadPath "FirewallAppBlocker"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        if (!(Test-Path -Path $FabZipPath)) {
            Write-Host "Downloading Firewall App Blocker tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri $FabDownloadUrl -OutFile $FabZipPath -UseBasicParsing -Verbose
            if ((Get-Item $FabZipPath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt."
            }
        }
        Write-Host "Extracting Firewall App Blocker tool..." -ForegroundColor Green
        if (Test-Path -Path $FabExtractPath) {
            Remove-Item -Path $FabExtractPath -Recurse -Force
        }
        try {
            [System.IO.Compression.ZipFile]::ExtractToDirectory($FabZipPath, $FabExtractPath)
        }
        catch {
            throw "Failed to extract the ZIP file. It may be corrupt or incomplete."
        }
        $FabExecutable = Get-ChildItem -Path $FabExtractPath -Recurse -Filter "Fab_x64.exe" | Select-Object -First 1
        if (-Not $FabExecutable) {
            throw "Fab_x64.exe not found in $FabExtractPath"
        }
        $Arguments = $Command
        if ($FilePath) {
            $Arguments += " $FilePath"
        }
        Write-Verbose -Message "Starting Firewall App Blocker with arguments: $Arguments"
        if ($StartApplication) {
            Start-Process -FilePath $FabExecutable.FullName
        }
        else {
            Start-Process -FilePath $FabExecutable.FullName -ArgumentList $Arguments -WindowStyle Hidden -Wait
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "Firewall operation '$Command' completed." -ForegroundColor Cyan
        if ($RemoveFirewallAppBlocker) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
