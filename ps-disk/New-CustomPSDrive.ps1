#Requires -Version 2.0
Function New-CustomPSDrive {
    <#
    .SYNOPSIS
    Creates a new PowerShell advanced drive with customizable options.

    .DESCRIPTION
    This function creates a new PowerShell advanced drive, allowing you to define various parameters such as the drive path, name, description, scope, and provider.

    .PARAMETER Path
    Path where the new drive will be created, defaults to the current location.
    .PARAMETER Name
    Name of the new drive, if not provided, the function automatically generates a name based on the current location.
    .PARAMETER First
    Whether the drive name should be based on the first word in the current location's name.
    .PARAMETER Description
    Specifies the description for the new drive, defaults to "Created [current date]".
    .PARAMETER Scope
    Scope of the new drive, valid values are "Global", "Local", "Script", or "User". Defaults to "Global".
    .PARAMETER PSProvider
    PowerShell provider for the new drive, defaults to the provider of the specified path.

    .EXAMPLE
    New-CustomPSDrive -Path "C:\Temp" -Name "DataDrive" -Description "Data drive for storing files" -Scope "Local"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$Path = (Get-Location).Path,
        
        [Parameter(Mandatory = $false)]
        [string]$Name,
    
        [Parameter(Mandatory = $false)]
        [switch]$First,
        
        [Parameter(Mandatory = $false)]
        [string]$Description = "Created $(Get-Date)",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Global", "Local", "Script", "User")]
        [string]$Scope = "Global",

        [Parameter(Mandatory = $false)]
        [ValidateSet("FileSystem", "Registry", "Variable", "Certificate")]
        [string]$PSProvider = (Get-Item -Path $Path).PSProvider.Name
    )
    BEGIN {
        Write-Verbose -Message "Starting $($MyInvocation.Mycommand)"
    }
    PROCESS {
        try {
            $CurrentLocation = Get-Item -Path $Path
            if (-not $Name) {
                $Pattern = if ($First) { "^\w+" } else { "\w+$" }
                if ($CurrentLocation.Name -match $Pattern) {
                    $Name = $matches[0]
                }
                else {
                    Write-Warning -Message "$Path doesn't meet the criteria!"
                    return
                }
            }
        }
        catch {
            Write-Host "Error: $_" -ForegroundColor DarkRed
        }
    }
    END {
        Write-Verbose -Message "Ending $($MyInvocation.Mycommand)"
        if ($Name) {
            Write-Verbose -Message "Testing $($Name):"
            if (-not (Test-Path -Path "$($Name):")) {
                $Params = @{
                    Name        = $Name
                    PSProvider  = $PSProvider
                    Root        = $Path
                    Description = $Description
                    Scope       = $Scope
                }
                try {
                    if ($PSCmdlet.ShouldProcess("$($Name):", "Create PSDrive")) {
                        Write-Verbose -Message "Creating PSDrive for $Name"
                        New-PSDrive @Params -ErrorAction Stop -Verbose
                    }
                }
                catch {
                    Write-Error -Message "Failed to create PSDrive: $_"
                }
            }
            else {
                Write-Warning -Message "A PSDrive for $Name already exists!"
            }
        }
    }
}
