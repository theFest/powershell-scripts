function New-WindowsServerVM {
    <#
    .SYNOPSIS
    Creates a new Windows Server virtual machine (VM) using Hyper-V.

    .DESCRIPTION
    This function downloads a Windows Server virtual hard disk (VHD) image from Microsoft, creates a new virtual machine with Hyper-V, and attaches the downloaded VHD to the VM.

    .EXAMPLE
    New-WindowsServerVM -VMName "WindowsServerEvaluation" -VMPath "C:\VMs" -Version 2025 -VRAM 4GB -VCores 2 -VHDPath "C:\VHDs\2025.vhd" -Verbose

    .NOTES
    Information on sizes of Windows Server versions:
    ~2012 --> 8,0 GB { 9600.16415.amd64fre.winblue_refresh.130928-2229_server_serverdatacentereval_en-us.vhd }
    ~2016 --> 6,9 GB { Windows_Server_2016_Datacenter_EVAL_en-us_14393_refresh.ISO } --> not fully supported atm!
    ~2019 --> 8,9 GB { 17763.737.amd64fre.rs5_release_svc_refresh.190906-2324_server_serverdatacentereval_en-us_1.vhd }
    ~2022 --> 10  GB { 20348.169.amd64fre.fe_release_svc_refresh.210806-2348_server_serverdatacentereval_en-us.vhd }
    ~2025 --> 11  GB { VHD - 26100.1.amd64fre.ge_release.240331-1435_server_serverdatacentereval_en-us.vhd }
    ~2025 --> 9,3 GB { ISO - 26100.1.240331-1435.ge_release_SERVER_EVAL_x64FRE_en-us.iso }
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Version of Windows Server to use for the VM")]
        [ValidateSet("2012", "2016", "2019", "2022", "2025")]
        [string]$Version,

        [Parameter(Mandatory = $true, HelpMessage = "Name of the virtual machine to be created")]
        [ValidateNotNullOrEmpty()]
        [string]$VMName,

        [Parameter(Mandatory = $true, HelpMessage = "Path where the virtual machine files will be stored")]
        [ValidateNotNullOrEmpty()]
        [string]$VMPath,

        [Parameter(Mandatory = $true, HelpMessage = "Path where the downloaded VHD file will be stored")]
        [ValidateNotNullOrEmpty()]
        [string]$VHDPath,

        [Parameter(Mandatory = $false, HelpMessage = "Amount of memory (RAM) allocated to the virtual machine in gigabytes")]
        [int64]$VRAM = 2GB,

        [Parameter(Mandatory = $false, HelpMessage = "Number of virtual CPU cores allocated to the virtual machine, default is 2")]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$VCores = 2,

        [Parameter(Mandatory = $false, HelpMessage = "Generation of the virtual machine, default is 1")]
        [ValidateSet("1", "2")]
        [string]$Generation = "1"
    )
    $URLs = @{
        "2012" = 'https://go.microsoft.com/fwlink/p/?linkid=2195172&clcid=0x409&culture=en-us&country=us' # VHD!
        "2016" = 'https://go.microsoft.com/fwlink/p/?LinkID=2195174&clcid=0x409&culture=en-us&country=us' # ISO? /VHD?
        "2019" = 'https://go.microsoft.com/fwlink/p/?linkid=2195334&clcid=0x409&culture=en-us&country=us' # VHD!
        "2022" = 'https://go.microsoft.com/fwlink/p/?linkid=2195166&clcid=0x409&culture=en-us&country=us' # VHD!
        "2025" = 'https://go.microsoft.com/fwlink/?linkid=2268774&clcid=0x409&culture=en-us&country=us'   # VHD! / ISO?
    }

    Write-Verbose -Message "Validating version..."
    if (-not $URLs.ContainsKey($Version)) {
        Write-Warning -Message "Invalid version specified! - Supported versions: $($URLs.Keys -join ', ')"
        return
    }
    $URL = $URLs[$Version]
    Write-Verbose -Message "Setting default VHDPath if not provided"
    if (-not $VHDPath) {
        $VHDPath = Join-Path -Path $env:TEMP -ChildPath "WindowsServerVHDs\$Version.vhd"
    }
    Write-Verbose -Message "Creating temporary directory if it doesn't exist"
    $TempDir = Split-Path -Path $VHDPath
    if (-not (Test-Path -Path $TempDir)) {
        New-Item -ItemType Directory -Path $TempDir | Out-Null
    }
    try {
        Write-Verbose -Message "Download of VHD(Version: $Version) is about to start..."
        Write-Host "Downloading Version: $Version, please be patient..." -ForegroundColor DarkYellow
        Invoke-WebRequest -Uri $URL -OutFile $VHDPath -UseBasicParsing -Verbose
        Write-Host "Creating VM..." -ForegroundColor Yellow
        $VmParams = @{
            Name               = $VMName
            MemoryStartupBytes = $VRAM
            Path               = $VMPath
        }
        if ($Version -eq "2016") {
            New-VM -Name $VMName -Path $VMPath -MemoryStartupBytes $VRAM -Generation $Generation -BootDevice CD -NoVHD
        }
        else {
            New-VM @VmParams -Generation $Generation -Verbose
            Write-Verbose -Message "Attaching VHD to VM..."
            Write-Host "Attaching VHD to VM..." -ForegroundColor DarkCyan
            Add-VMHardDiskDrive -VMName $VMName -Path $VHDPath -Verbose
        }
        Write-Host "VM creation completed. VM name: $VMName" -ForegroundColor DarkGreen
    }
    catch {
        Write-Error -Message "Failed to create VM: $_"
    }
    finally {
        Start-Sleep -Seconds 8
        if ((Get-VM -Name $VMName).State -eq "Running") {
            Write-Host "VM: $VMName is running" -ForegroundColor DarkGreen
        }
        else {
            Write-Warning -Message "VM: $VMName is not running, starting in 2 seconds..."
            Start-Sleep -Seconds 10
            Start-VM -Name $VMName -Verbose
        }
    }
}
