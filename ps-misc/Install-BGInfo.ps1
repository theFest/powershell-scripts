#Requires -Version 5.0 -Modules BitsTransfer
Function Install-BGInfo {
    <#
    .SYNOPSIS
    Installs and configures BGInfo on the system.

    .DESCRIPTION
    This function installs BGInfo on the system, downloads necessary files, sets up registry keys for auto-start, and configures BGInfo options such as timeout, popup window, suppression of error messages, taskbar icon, and more.

    .PARAMETER BgInfoFolder
    Folder where BGInfo will be installed.
    .PARAMETER BgInfoFolderContent
    Content of the BGInfo folder.
    .PARAMETER ItemType
    The type of item to create.
    .PARAMETER BgInfoUrl
    URL to download BGInfo.
    .PARAMETER LogonBgiUrl
    URL to download the logon BGI file.
    .PARAMETER BgInfoZip
    Specifies the path to the BGInfo ZIP file.
    .PARAMETER BgInfoEula
    Specifies the path to the BGInfo EULA file.
    .PARAMETER LogonBgiFile
    Specifies the path to the logon BGI file.
    .PARAMETER BgInfoRegPath
    Registry path to add BGInfo for auto-start.
    .PARAMETER BgInfoRegkey
    Registry key for BGInfo.
    .PARAMETER BgInfoRegkeyValue
    Registry value data for BGInfo.
    .PARAMETER Timer
    Specifies the timeout value for the countdown timer, in seconds.
    .PARAMETER Popup
    Causes BGInfo to create a popup window containing the configured information without updating the desktop.
    .PARAMETER Silent
    Suppresses error messages within BGInfo app.
    .PARAMETER Taskbar
    Causes BGInfo to place an icon in the taskbar's status area without updating the desktop.
    .PARAMETER All
    BGInfo should change the wallpaper for any and all users currently logged in to the system.
    .PARAMETER Log
    Causes BGInfo to write errors to the specified log file instead of generating a warning dialog box.
    .PARAMETER Rtf
    Causes BGInfo to write its output text to an RTF file.

    .EXAMPLE
    Install-BGInfo -Taskbar -Verbose

    .NOTES
    v0.0.1
    #>
    [CmdletBinding(ConfirmImpact = "Low")]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Folder where BGInfo will be installed")]
        [ValidateNotNullOrEmpty()]
        [string]$BgInfoFolder = ('{0}\BgInfo' -f $env:ProgramFiles),

        [Parameter(Mandatory = $false, HelpMessage = "Content of the BGInfo folder")]
        [ValidateNotNullOrEmpty()]
        [string]$BgInfoFolderContent = ('{0}\*' -f $BgInfoFolder),

        [Parameter(Mandatory = $false, HelpMessage = "Type of item to create")]
        [ValidateSet("File", "Directory")]
        [string]$ItemType = "Directory",

        [Parameter(Mandatory = $false, HelpMessage = "URL to download BGInfo")]
        [ValidateNotNullOrEmpty()]
        [string]$BgInfoUrl = "https://download.sysinternals.com/files/BGInfo.zip",

        [Parameter(Mandatory = $false, HelpMessage = "URL to download the logon BGI file")]
        [ValidateNotNullOrEmpty()]
        [string]$LogonBgiUrl,

        [Parameter(Mandatory = $false, HelpMessage = "Path to the BGInfo ZIP file")]
        [ValidateNotNullOrEmpty()]
        [string]$BgInfoZip = ('{0}\BgInfo.zip' -f $BgInfoFolder),

        [Parameter(Mandatory = $false, HelpMessage = "Path to the BGInfo EULA file")]
        [ValidateNotNullOrEmpty()]
        [string]$BgInfoEula = ('{0}\Eula.txt' -f $BgInfoFolder),

        [Parameter(Mandatory = $false, HelpMessage = "Path to the logon BGI file")]
        [ValidateNotNullOrEmpty()]
        [string]$LogonBgiFile = ('{0}\logon.bgi' -f $BgInfoFolder),

        [Parameter(Mandatory = $false, HelpMessage = "Registry path to add BGInfo for auto-start")]
        [ValidateNotNullOrEmpty()]
        [string]$BgInfoRegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",

        [Parameter(Mandatory = $false, HelpMessage = "Registry key for BGInfo")]
        [ValidateNotNullOrEmpty()]
        [string]$BgInfoRegkey = "BgInfo",

        [Parameter(Mandatory = $false, HelpMessage = "Registry value data for BGInfo")]
        [ValidateNotNullOrEmpty()]
        [string]$BgInfoRegkeyValue = """$BgInfoFolder\Bginfo64.exe"" ""$BgInfoFolder\logon.bgi"" /timer:0 /nolicprompt",

        [Parameter(Mandatory = $false, HelpMessage = "Specifies the timeout value for the countdown timer, in seconds")]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$Timer = 0,

        [Parameter(Mandatory = $false, HelpMessage = "Causes BGInfo to create a popup window containing the configured information without updating the desktop")]
        [switch]$Popup,

        [Parameter(Mandatory = $false, HelpMessage = "Suppresses error messages")]
        [switch]$Silent,

        [Parameter(Mandatory = $false, HelpMessage = "Causes BGInfo to place an icon in the taskbar's status area without updating the desktop")]
        [switch]$Taskbar,

        [Parameter(Mandatory = $false, HelpMessage = "Specifies that BGInfo should change the wallpaper for any and all users currently logged in to the system")]
        [switch]$All,

        [Parameter(Mandatory = $false, HelpMessage = "Causes BGInfo to write errors to the specified log file instead of generating a warning dialog box")]
        [ValidateNotNullOrEmpty()]
        [string]$Log,

        [Parameter(Mandatory = $false, HelpMessage = "Causes BGInfo to write its output text to an RTF file")]
        [switch]$Rtf
    )
    BEGIN {
        Write-Verbose -Message "Ensuring BitsTransfer module is available..."
        if (-not (Get-Module -Name "BitsTransfer" -ListAvailable)) {
            Write-Error -Message "BitsTransfer module is required for this function. Please install it first."
            return
        }
        Write-Verbose -Message "Checking if BGInfo folder exists..."
        if (!(Test-Path -Path $BgInfoFolder)) {
            Write-Verbose "Creating BGInfo folder..."
            $null = New-Item -Path $BgInfoFolder -ItemType $ItemType -Force
        }
        else {
            Write-Verbose -Message "Clearing BGInfo folder contents..."
            $null = Remove-Item -Path $BgInfoFolderContent -Force -Recurse -ErrorAction SilentlyContinue
        }
    }
    PROCESS {
        Write-Verbose -Message "Downloading BGInfo from $($BgInfoUrl.AbsoluteUri)..."
        Start-BitsTransfer -Source $BgInfoUrl -Destination $BgInfoZip -ErrorAction Stop -Verbose
        if (!(Test-Path -Path $BgInfoZip -ErrorAction SilentlyContinue)) {
            Write-Error -Message "BGInfo download failed!"
            return
        }
        Write-Verbose -Message "Extracting BGInfo archive..."
        try {
            Expand-Archive -Path $BgInfoZip -DestinationPath $BgInfoFolder -Force -ErrorAction Stop -Verbose
        }
        catch {
            Write-Verbose -Message "Fallback extraction method due to Expand-Archive failure..."
            $null = Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory($BgInfoZip, $BgInfoFolder)
        }
        Write-Verbose -Message "Removing temporary files..."
        if ($LogonBgiUrl) {
            $null = Remove-Item -Path $BgInfoZip, $BgInfoEula -Force -ErrorAction SilentlyContinue
            Write-Verbose -Message "Downloading custom logon.bgi file from $($LogonBgiUrl.AbsoluteUri)..."
            Invoke-WebRequest -Uri $LogonBgiUrl -OutFile $LogonBgiFile -DisableKeepAlive -ErrorAction Stop -Verbose
            if (!(Test-Path -Path $LogonBgiFile -ErrorAction SilentlyContinue)) {
                Write-Error -Message "Custom logon.bgi file download failed!"
                return
            }
        }
        Write-Verbose -Message "Verifying BGInfo executable existence..."
        if (!(Test-Path -Path ('{0}\Bginfo64.exe' -f $BgInfoFolder) -ErrorAction SilentlyContinue)) {
            Write-Error -Message "BGInfo executable not found!"
            return
        }
        Write-Verbose -Message "Removing existing BGInfo registry key if exists..."
        if (Test-Path -Path $BgInfoRegPath) {
            Remove-ItemProperty -Path $BgInfoRegPath -Name $BgInfoRegkey -Force -ErrorAction SilentlyContinue -Verbose
        }
        Write-Verbose -Message "Creating BGInfo registry key to enable AutoStart..."
        $null = New-ItemProperty -Path $BgInfoRegPath -Name $BgInfoRegkey -Value $BgInfoRegkeyValue -PropertyType $BgInfoRegType -Force -ErrorAction SilentlyContinue
    }
    END {
        $BgInfoArgs = @()
        if ($Timer -ne 0) {
            $BgInfoArgs += "/timer:$Timer"
        }
        if ($Popup) {
            $BgInfoArgs += "/popup"
        }
        if ($Silent) {
            $BgInfoArgs += "/silent"
        }
        if ($Taskbar) {
            $BgInfoArgs += "/taskbar"
        }
        if ($All) {
            $BgInfoArgs += "/all"
        }
        if ($Log) {
            $BgInfoArgs += "/log:$Log"
        }
        if ($Rtf) {
            $BgInfoArgs += "/rtf"
        }
        $BgInfoArgsString = $BgInfoArgs -join ' '
        Write-Verbose -Message "Starting BGInfo with arguments: $BgInfoArgsString"
        $null = Start-Process -FilePath ('{0}\Bginfo64.exe' -f $BgInfoFolder) -ArgumentList "$BgInfoArgsString" -ErrorAction SilentlyContinue
    }
}
