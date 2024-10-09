function New-Windows11VM {
    <#
    .SYNOPSIS
    Creates a new Windows 11 virtual machine (VM) using Hyper-V.

    .DESCRIPTION
    This function downloads a Windows 11 ISO image, creates a new virtual machine with Hyper-V, attaches the downloaded ISO to the VM, and provides an option to start the VM after creation.

    .EXAMPLE
    New-Windows11VM -VMName "Win11VM" -VMPath "C:\VMs" -VRAM 4GB -VCores 2 -ISOPath "C:\ISOs\Win11.iso" -Verbose

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Specifies the name of the virtual machine to be created")]
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
        [string]$Generation = "2"
    )
    BEGIN {
        Write-Verbose -Message "Starting the Windows 11 VM creation process..."
    }
    PROCESS {
        $URL = 'https://archive.org/download/win-11-23-h-2-english-international-x-64v-2_202409/Win11_23H2_EnglishInternational_x64v2.iso' # 64bit ISO (~6.3 GB)
        Write-Verbose -Message "Creating temporary directory if it doesn't exist"
        $TempDir = Split-Path -Path $ISOPath
        if (-not (Test-Path -Path $TempDir)) {
            New-Item -ItemType Directory -Path $TempDir | Out-Null
        }
        if (-not (Test-Path -Path $ISOPath)) {
            try {
                Write-Verbose -Message "Downloading ISO for Windows 11..."
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
