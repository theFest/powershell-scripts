Function New-WindowsServerVM {
    <#
    .SYNOPSIS
    Creates a new Windows Server virtual machine (VM) using Hyper-V.

    .DESCRIPTION
    This function downloads a Windows Server virtual hard disk (VHD) image from Microsoft, creates a new virtual machine with Hyper-V, and attaches the downloaded VHD to the VM.

    .PARAMETER Version
    Version of Windows Server to use for the VM, values are "2012", "2016", "2019", or "2022".
    .PARAMETER VMName
    Specifies the name of the virtual machine to be created.
    .PARAMETER VMPath
    Path where the virtual machine files will be stored.
    .PARAMETER VHDPath
    Path where the downloaded VHD file will be stored.
    .PARAMETER VRAM
    Amount of memory (RAM) allocated to the virtual machine in gigabytes, default is 2GB. Example values: "2GB", "4GB", "6GB", "8GB", "16GB", "32GB", "64GB", "128GB".
    .PARAMETER VCores
    Number of virtual CPU cores allocated to the virtual machine, default is 2.
    .PARAMETER Generation
    Generation of the virtual machine, default is 1.

    .EXAMPLE
    New-WindowsServerVM -VMName "WindowsServerEvaluation" -VMPath "C:\VMs" -Version 2012 -VRAM 4GB -VCores 2 -VHDPath "C:\VHDs\2012.vhd" -Verbose

    .NOTES
    Information on sizes of Windows Server versions:
    ~2012 --> 8,0 GB { 9600.16415.amd64fre.winblue_refresh.130928-2229_server_serverdatacentereval_en-us.vhd }
    ~2016 --> 6,9 GB { Windows_Server_2016_Datacenter_EVAL_en-us_14393_refresh.ISO }
    ~2019 --> 8,9 GB { 17763.737.amd64fre.rs5_release_svc_refresh.190906-2324_server_serverdatacentereval_en-us_1.vhd }
    ~2022 --> 10 GB  { 20348.169.amd64fre.fe_release_svc_refresh.210806-2348_server_serverdatacentereval_en-us.vhd }
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("2012", "2016", "2019", "2022")]
        [string]$Version,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$VMName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$VMPath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$VHDPath,

        [Parameter(Mandatory = $false)]
        [int64]$VRAM = 2GB,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$VCores = 2,

        [Parameter(Mandatory = $false)]
        [ValidateSet("1", "2")]
        [string]$Generation = "1"
    )
    $URLs = @{
        "2012" = 'https://go.microsoft.com/fwlink/p/?linkid=2195172&clcid=0x409&culture=en-us&country=us'
        "2016" = 'https://go.microsoft.com/fwlink/p/?LinkID=2195174&clcid=0x409&culture=en-us&country=us'#!--> not fully supported atm
        "2019" = 'https://go.microsoft.com/fwlink/p/?linkid=2195334&clcid=0x409&culture=en-us&country=us'
        "2022" = 'https://go.microsoft.com/fwlink/p/?linkid=2195166&clcid=0x409&culture=en-us&country=us'
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
            Start-Sleep -Seconds 2
            Start-VM -Name $VMName -Verbose
        }
    }
}
