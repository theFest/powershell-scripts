function Block-EdgeBrowser {
    <#
    .SYNOPSIS
    Executes operations using the Edge Blocker tool.

    .DESCRIPTION
    This function downloads and executes EdgeBlock to block or unblock Microsoft Edge and Webview2 components.

    .EXAMPLE
    Block-EdgeBrowser -Command '/B'
    Block-EdgeBrowser -Command '/IJ'
    Block-EdgeBrowser -Command '/B' -Component 'E'
    Block-EdgeBrowser -Command '/IJ' -Component 'W'
    Block-EdgeBrowser -Command '/B' -Component 'E' -StartApplication
    Block-EdgeBrowser -Command '/IJ' -Component 'W' -RemoveEdgeBlocker

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Specify the command to execute with EdgeBlock_x6h.exe")]
        [ValidateSet('/B', '/IJ')]
        [string]$Command,

        [Parameter(Mandatory = $false, HelpMessage = "Component to target ('E' for Edge, 'W' for Webview2)")]
        [ValidateSet('E', 'W')]
        [string]$Component,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading the Edge Blocker tool")]
        [uri]$EdgeBlockerDownloadUrl = "https://www.sordum.org/files/download/edge-blocker/EdgeBlock.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where the Edge Blocker tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\EdgeBlocker",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveEdgeBlocker,

        [Parameter(Mandatory = $false, HelpMessage = "Start the Edge Blocker application after extraction")]
        [switch]$StartApplication
    )
    $EdgeBlockerZipPath = Join-Path $DownloadPath "EdgeBlock.zip"
    $EdgeBlockerExtractPath = Join-Path $DownloadPath "EdgeBlock"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        if (!(Test-Path -Path $EdgeBlockerZipPath)) {
            Write-Host "Downloading Edge Blocker tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri $EdgeBlockerDownloadUrl -OutFile $EdgeBlockerZipPath -UseBasicParsing -Verbose
            if ((Get-Item $EdgeBlockerZipPath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt."
            }
        }
        Write-Host "Extracting Edge Blocker tool..." -ForegroundColor Green
        if (Test-Path -Path $EdgeBlockerExtractPath) {
            Remove-Item -Path $EdgeBlockerExtractPath -Recurse -Force
        }
        try {
            [System.IO.Compression.ZipFile]::ExtractToDirectory($EdgeBlockerZipPath, $DownloadPath)
        }
        catch {
            throw "Failed to extract the ZIP file. It may be corrupt or incomplete."
        }
        $EdgeBlockerExecutable = Join-Path $DownloadPath "EdgeBlock\EdgeBlock_x64.exe"
        if (-Not (Test-Path -Path $EdgeBlockerExecutable)) {
            throw "EdgeBlock_x64.exe not found in $DownloadPath\EdgeBlock"
        }
        $Arguments = $Command
        if ($Component) {
            $Arguments += " /$Component"
        }
        Write-Verbose -Message "Starting Edge Blocker with arguments: $Arguments"
        if ($StartApplication) {
            Start-Process -FilePath $EdgeBlockerExecutable
        }
        else {
            Start-Process -FilePath $EdgeBlockerExecutable -ArgumentList $Arguments -WindowStyle Hidden -Wait
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "Edge Blocker operation '$Command' completed." -ForegroundColor Cyan
        if ($RemoveEdgeBlocker) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
