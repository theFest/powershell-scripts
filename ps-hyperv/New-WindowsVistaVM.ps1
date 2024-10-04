function New-WindowsVistaVM {
    <#
    .SYNOPSIS
    Creates a new Windows Vista virtual machine (VM) using Hyper-V.

    .DESCRIPTION
    This function downloads a Windows Vista ISO image, creates a new virtual machine with Hyper-V, and attaches the downloaded ISO to the VM.

    .EXAMPLE
    New-WindowsVistaVM -VMName "VistaVM" -VMPath "C:\VMs" -VRAM 2GB -VCores 1 -ISOPath "C:\ISOs\Vista.iso" -Verbose

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

        [Parameter(Mandatory = $false, HelpMessage = "Amount of memory (RAM) allocated to the virtual machine in gigabytes, default is 2GB")]
        [int64]$VRAM = 2GB,

        [Parameter(Mandatory = $false, HelpMessage = "Number of virtual CPU cores allocated to the virtual machine, default is 1")]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$VCores = 1,

        [Parameter(Mandatory = $false, HelpMessage = "Generation of the virtual machine, default is 1 since Windows Vista requires Gen1 VMs for compatibility")]
        [ValidateSet("1", "2")]
        [string]$Generation = "1"
    )
    BEGIN {
        Write-Verbose -Message "Starting the Windows Vista VM creation process..."
    }
    PROCESS {
        $URL = 'https://archive.org/download/windows-vista-build-5788/windows%20vista%20build%205788.iso' # ISO (~3.4 GB)
        Write-Verbose -Message "Creating temporary directory if it doesn't exist"
        $TempDir = Split-Path -Path $ISOPath
        if (-not (Test-Path -Path $TempDir)) {
            New-Item -ItemType Directory -Path $TempDir | Out-Null
        }
        if (-not (Test-Path -Path $ISOPath)) {
            try {
                Write-Verbose -Message "Downloading ISO for Windows Vista..."
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
