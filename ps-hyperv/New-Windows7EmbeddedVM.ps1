function New-Windows7EmbeddedVM {
    <#
    .SYNOPSIS
    Creates a new Windows 7 Embedded virtual machine (VM) using Hyper-V.

    .DESCRIPTION
    This function downloads a Windows 7 Embedded virtual hard disk (VHD) image in ISO format, creates a new virtual machine with Hyper-V, and attaches the downloaded ISO to the VM.

    .EXAMPLE
    New-Windows7EmbeddedVM -VMName "Win7EmbeddedVM" -VMPath "C:\VMs" -VRAM 4GB -VCores 2 -ISOPath "C:\ISOs\Win7Embedded.iso" -Verbose

    .NOTES
    - Windows 7 Embedded is part of the Windows Embedded Standard 7 series, and this script uses an ISO image that can be converted into a VHD during VM setup.
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "SSpecifies the name of the virtual machine to be created")]
        [ValidateNotNullOrEmpty()]
        [string]$VMName,

        [Parameter(Mandatory = $true, HelpMessage = "Path where the virtual machine files will be stored")]
        [ValidateNotNullOrEmpty()]
        [string]$VMPath,

        [Parameter(Mandatory = $true, HelpMessage = "Path where the downloaded ISO file will be stored")]
        [ValidateNotNullOrEmpty()]
        [string]$ISOPath,

        [Parameter(Mandatory = $false, HelpMessage = "Amount of memory (RAM) allocated to the virtual machine in gigabytes, default is 2GB")]
        [int64]$VRAM = 2GB,

        [Parameter(Mandatory = $false, HelpMessage = "Number of virtual CPU cores allocated to the virtual machine, default is 2")]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$VCores = 2,

        [Parameter(Mandatory = $false, HelpMessage = "Generation of the virtual machine, default is 1")]
        [ValidateSet("1", "2")]
        [string]$Generation = "1"
    )
    $URL = 'https://archive.org/download/standard-7-sp-1-32bit-ibw_202211/Standard%207%20SP1%2064bit%20IBW.iso'
    Write-Verbose -Message "Creating temporary directory if it doesn't exist"
    $TempDir = Split-Path -Path $ISOPath
    if (-not (Test-Path -Path $TempDir)) {
        New-Item -ItemType Directory -Path $TempDir | Out-Null
    }
    try {
        Write-Verbose -Message "Download of ISO for Windows 7 Embedded is about to start..."
        Invoke-WebRequest -Uri $URL -OutFile $ISOPath -UseBasicParsing -Verbose
        Write-Host "Creating VM..." -ForegroundColor Yellow
        New-VM -Name $VMName -MemoryStartupBytes $VRAM -Path $VMPath -Generation $Generation -Verbose
        Write-Verbose -Message "Attaching ISO to VM..."
        Add-VMDvdDrive -VMName $VMName -Path $ISOPath -Verbose
        Write-Host "VM creation completed. VM name: $VMName" -ForegroundColor DarkGreen
    }
    catch {
        Write-Error -Message "Failed to create VM: $_"
    }
}
