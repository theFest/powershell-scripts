function New-Windows10LtscVM {
    <#
    .SYNOPSIS
    Creates a new Windows 10 LTSC virtual machine (VM) using Hyper-V.

    .DESCRIPTION
    This function downloads a Windows 10 LTSC ISO image (x86 or x64), creates a new virtual machine with Hyper-V, and attaches the downloaded ISO to the VM.

    .EXAMPLE
    New-Windows10LtscVM -VMName "Win10LTSCVM" -VMPath "C:\VMs" -VRAM 4GB -VCores 2 -Architecture "x64" -ISOPath "C:\ISOs\Win10_LTSC_x64.iso" -Verbose

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Name of the virtual machine to be created")]
        [ValidateNotNullOrEmpty()]
        [string]$VMName,

        [Parameter(Mandatory = $true, HelpMessage = "Path where the virtual machine files will be stored")]
        [ValidateNotNullOrEmpty()]
        [string]$VMPath,

        [Parameter(Mandatory = $true, HelpMessage = "Path where the downloaded ISO file will be stored")]
        [ValidateNotNullOrEmpty()]
        [string]$ISOPath,

        [Parameter(Mandatory = $false, HelpMessage = "Amount of memory (RAM) allocated to the virtual machine in gigabytes, default is 4GB")]
        [int64]$VRAM = 4GB,

        [Parameter(Mandatory = $false, HelpMessage = "Number of virtual CPU cores allocated to the virtual machine, default is 2")]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$VCores = 2,

        [Parameter(Mandatory = $false, HelpMessage = "Generation of the virtual machine, default is 2")]
        [ValidateSet("1", "2")]
        [string]$Generation = "2",

        [Parameter(Mandatory = $true, HelpMessage = "Specifies whether to use x86 or x64 architecture for the VM")]
        [ValidateSet("x86", "x64")]
        [string]$Architecture
    )
    BEGIN {
        Write-Verbose -Message "Starting the Windows 10 LTSC VM creation process..."
    }
    PROCESS {
        if ($Architecture -eq "x86") {
            $URL = 'https://archive.org/download/win-10-ltsc-x-86-halazy-com/Win10_LTSC_x86_Halazy.Com.iso' # 32bit ISO (~2.7 GB)
        }
        elseif ($Architecture -eq "x64") {
            $URL = 'https://archive.org/download/win-10-ltsc-x-64-halazy-com/Win10_LTSC_x64_Halazy.Com.iso' # 64bit ISO (~3.8 GB)
        }
        Write-Verbose -Message "Creating temporary directory if it doesn't exist"
        $TempDir = Split-Path -Path $ISOPath
        if (-not (Test-Path -Path $TempDir)) {
            New-Item -ItemType Directory -Path $TempDir | Out-Null
        }
        if (-not (Test-Path -Path $ISOPath)) {
            try {
                Write-Verbose -Message "Downloading ISO for Windows 10 LTSC ($Architecture)..."
                Invoke-WebRequest -Uri $URL -OutFile $ISOPath -UseBasicParsing -Verbose
            }
            catch {
                Write-Error -Message "Failed to download ISO: $_"
                return
            }
        }
        else {
            Write-Host "ISO already exists. Skipping download." -ForegroundColor Green
        }
        Write-Host "Creating VM..." -ForegroundColor Yellow
        try {
            New-VM -Name $VMName -MemoryStartupBytes $VRAM -Path $VMPath -Generation $Generation -Verbose
            Write-Verbose -Message "Attaching ISO to VM..."
            Add-VMDvdDrive -VMName $VMName -Path $ISOPath -Verbose
        }
        catch {
            Write-Error -Message "Failed to create VM: $_"
            return
        }
    }
    END {
        Write-Host "VM creation completed. VM name: $VMName" -ForegroundColor DarkGreen
        $StartVM = Read-Host "Do you want to start the VM now? (Y/N)"
        if ($StartVM -eq 'Y' -or $StartVM -eq 'y') {
            try {
                Start-VM -Name $VMName -Verbose
                Write-Host "VM started successfully." -ForegroundColor Green
            }
            catch {
                Write-Error -Message "Failed to start the VM: $_"
            }
        }
        else {
            Write-Host "VM was created but not started." -ForegroundColor Yellow
        }
    }
}
