function New-Windows7EmbeddedVM {
    <#
    .SYNOPSIS
    Creates a new Windows 7 Embedded virtual machine (VM) using Hyper-V.

    .DESCRIPTION
    This function downloads a Windows 7 Embedded ISO image (32-bit or 64-bit), creates a new virtual machine with Hyper-V, attaches the downloaded ISO to the VM, and provides the option to turn on the VM upon completion. If the ISO is already fully downloaded, the function skips the download process.

    .EXAMPLE
    New-Windows7EmbeddedVM -VMName "Win7EmbeddedVM" -VMPath "C:\VMs" -VRAM 4GB -VCores 2 -ISOPath "C:\ISOs\Win7Embedded.iso" -Architecture 64bit -Verbose

    .NOTES
    v0.0.5
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

        [Parameter(Mandatory = $false, HelpMessage = "Amount of memory (RAM) allocated to the virtual machine in gigabytes, default is 2GB")]
        [int64]$VRAM = 2GB,

        [Parameter(Mandatory = $false, HelpMessage = "Number of virtual CPU cores allocated to the virtual machine, default is 2")]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$VCores = 2,

        [Parameter(Mandatory = $false, HelpMessage = "Generation of the virtual machine, default is 1")]
        [ValidateSet("1", "2")]
        [string]$Generation = "1",

        [Parameter(Mandatory = $true, HelpMessage = "Download 32-bit or 64-bit ISO of Windows 7 Embedded")]
        [ValidateSet("32bit", "64bit")]
        [string]$Architecture
    )
    BEGIN {
        $StartTime = Get-Date
        Write-Verbose -Message "Initiating ISO download, VM creation process, etc."
    }
    PROCESS {
        $URL = if ($Architecture -eq "32bit") {
            'https://archive.org/download/standard-7-sp-1-32bit-ibw_202211/Standard%207%20SP1%2032bit%20IBW.iso'
        }
        else {
            'https://archive.org/download/standard-7-sp-1-32bit-ibw_202211/Standard%207%20SP1%2064bit%20IBW.iso'
        }
        $IsoSizes = @{
            "32bit" = 2992934912; # 32bit ISO (~2.8 GB)
            "64bit" = 3625994240; # 64bit ISO (~3.4 GB)
        }
        if (Test-Path -Path $ISOPath) {
            $ExistingFileSize = (Get-Item $ISOPath).Length
            if ($ExistingFileSize -eq $IsoSizes[$Architecture]) {
                Write-Verbose -Message "ISO file already exists and is fully downloaded. Skipping download."
            }
            else {
                Write-Verbose -Message "Partial or corrupted ISO detected. Redownloading..."
                Remove-Item -Path $ISOPath -Force
                Invoke-WebRequest -Uri $URL -OutFile $ISOPath -UseBasicParsing -Verbose
            }
        }
        else {
            Write-Verbose -Message "Downloading $Architecture ISO for Windows 7 Embedded..."
            Invoke-WebRequest -Uri $URL -OutFile $ISOPath -UseBasicParsing -Verbose
        }
        Write-Host "Creating VM..." -ForegroundColor Yellow
        New-VM -Name $VMName -MemoryStartupBytes $VRAM -Path $VMPath -Generation $Generation -Verbose
        Write-Verbose -Message "Attaching ISO to VM..."
        Add-VMDvdDrive -VMName $VMName -Path $ISOPath -Verbose
    }
    END {
        Write-Host "VM creation completed. VM name: $VMName" -ForegroundColor DarkGreen
        $EndTime = Get-Date
        $ElapsedTime = New-TimeSpan -Start $StartTime -End $EndTime
        Write-Verbose -Message "Total time taken: $($ElapsedTime.TotalMinutes) minutes"
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
