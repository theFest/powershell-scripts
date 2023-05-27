Function DependenciesManager {
    <#
    .SYNOPSIS
    Simple script/tool that helps manage software dependencies.
    
    .DESCRIPTION
    DependenciesManager is a tool that makes it easier to manage software dependencies, packages, modules, cabinets, etc.
    
    .PARAMETER Action
    Mandatory - action to perform: Install or Remove.
    .PARAMETER Name
    Mandatory - enter the name of the dependency or feature.
    .PARAMETER Type
    Mandatory - choose a package type of the dependency or feature.
    .PARAMETER AdditionalParams
    NotMandatory - if you have any additional parameters, if required.
    .PARAMETER Source
    NotMandatory - the source for the installation package.
    .PARAMETER Silent
    NotMandatory - perform the installation or removal without displaying output.
    .PARAMETER Restart
    NotMandatory - perform the restart after installation or removal of package finishes.
    .PARAMETER RestartTime
    NotMandatory - countdown before restart after installation or removal of package finishes.

    .EXAMPLE
    DependenciesManager -Action Install -Name "NetFx3" -Type "Windows Feature"
    DependenciesManager -Action Install -Name "Az.Accounts" -Type "PowerShell Module"
    DependenciesManager -Action Install -Name "Microsoft.NET.Framework.4.8" -Type ".NET Framework"
    DependenciesManager -Action Install -Name "openjdk" -Type "Java Package" -Source "$env:USERPROFILE\Desktop\openjdk-14.0.2_windows-x64_bin.jar"
    DependenciesManager -Action Install -Name "GoogleChrome" -Type "Chocolatey Package"
    DependenciesManager -Action Install -Name "MyApp" -Type "Software Package" -Source "$env:USERPROFILE\Desktop\MyApp.exe"
    
    .NOTES
    v1.0
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Install", "Remove")]
        [string]$Action,
    
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Windows Feature", "PowerShell Module", ".NET Framework", "Java Package", "Chocolatey Package", "Software Package", "AppxProvisioned Package")]
        [string]$Type,
    
        [Parameter(Mandatory = $false)]
        [string[]]$AdditionalParams,

        [Parameter(Mandatory = $false)]
        [ValidateScript({
                if ($null -ne $Source) {
                    if (!(Test-Path $Source -PathType "Leaf")) {
                        throw "The specified file path '$Source' does not exist."
                    }
                }
                return $true
            })]
        [string]$Source,

        [Parameter(Mandatory = $false)]
        [switch]$Silent,

        [Parameter(Mandatory = $false)]
        [switch]$Restart,

        [Parameter(Mandatory = $false)]
        [int]$RestartTime = '12'
    )
    BEGIN {
        Write-Verbose -Message "Starting Dependencies Manager..."
    }
    PROCESS {
        switch ($Action) {
            "Install" {
                Write-Host "Installing $Name" -ForegroundColor Cyan -BackgroundColor Black
                switch ($Type) {
                    "Windows Feature" {
                        if (!$Silent) { Write-Host "Installing Windows Feature $Name" -ForegroundColor Green -BackgroundColor Black }
                        try {
                            $WinTypeCheck = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
                            if ($WinTypeCheck -like "*Windows Server*") {
                                Install-WindowsFeature $Name -IncludeAllSubFeature
                            }
                        }
                        catch {
                            Write-Host $_.Exception.Message -ForegroundColor Red -BackgroundColor Black
                        }
                    }
                    "PowerShell Module" {
                        if (!$Silent) { Write-Host "Installing PowerShell Module $Name" -ForegroundColor Green -BackgroundColor Black }
                        try {
                            Install-Module $Name
                        }
                        catch {
                            Write-Host $_.Exception.Message -ForegroundColor Red -BackgroundColor Black
                        }
                    }
                    ".NET Framework" {
                        if (!$Silent) { Write-Host "Installing .NET Framework $Name" -ForegroundColor Green -BackgroundColor Black }
                        try {
                            if ($Source) {
                                Add-WindowsPackage -Online -PackagePath $Source
                            }
                            else {
                                Add-WindowsCapability -Online -Name $Name
                            }
                        }
                        catch {
                            Write-Host $.Exception.Message -ForegroundColor Red -BackgroundColor Black
                        }
                    }
                    "Java Package" {
                        if (!$Silent) { Write-Host "Installing Java $Name" -ForegroundColor Green -BackgroundColor Black }
                        try {
                            if ($Source) {
                                Invoke-Expression -Command "java -jar $Source"
                            }
                            else {
                                Write-Host "Please specify a source for the Java installation package." -ForegroundColor Red -BackgroundColor Black
                            }
                        }
                        catch {
                            Write-Host $.Exception.Message -ForegroundColor Red -BackgroundColor Black
                        }
                    }
                    "Chocolatey Package" {
                        if (!$Silent) { Write-Host "Installing Chocolatey Package $Name" -ForegroundColor Green -BackgroundColor Black }
                        try {
                            choco install $Name
                        }
                        catch {
                            Write-Host $.Exception.Message -ForegroundColor Red -BackgroundColor Black
                        }
                    }
                    "Software Package" {
                        if (!$Silent) { Write-Host "Installing Software Package $Name" -ForegroundColor Green -BackgroundColor Black }
                        try {
                            if ($Source) {
                                if ($Source.EndsWith(".appxbundle")) {
                                    Add-AppxPackage -Path $Source
                                }
                                elseif ($Source.EndsWith(".cab")) {
                                    Add-WindowsPackage -Online -PackagePath $Source
                                }
                                else {
                                    if ($AdditionalParams) {
                                        Invoke-Expression -Command "$Source $AdditionalParams"
                                    }
                                    else {
                                        Invoke-Expression -Command "$Source"
                                    }
                                }
                            }
                            else {
                                Write-Host "Please specify a source for the software installation package." -ForegroundColor Red -BackgroundColor Black
                            }
                        }
                        catch {
                            Write-Host $_.Exception.Message -ForegroundColor Red -BackgroundColor Black
                        }
                    }
                    "AppxProvisioned Package" {
                        if (!$Silent) { Write-Host "Installing AppxProvisionedPackage $Name" -ForegroundColor Green -BackgroundColor Black }
                        try {
                            Add-AppxProvisionedPackage -Online -PackagePath $Source
                        }
                        catch {
                            Write-Host $_.Exception.Message -ForegroundColor Red -BackgroundColor Black
                        }
                    }             
                    default {
                        Write-Host "Error: Invalid option for name parameter." -ForegroundColor Red -BackgroundColor Black
                    }
                }
            }
            "Remove" {
                Write-Host "Removing $Name" -ForegroundColor Cyan -BackgroundColor Black
                switch ($Type) {
                    "Windows Feature" {
                        if (!$Silent) { Write-Host "Removing Windows Feature $Name" -ForegroundColor Green -BackgroundColor Black }
                        try {
                            $WinTypeCheck = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
                            if ($WinTypeCheck -like "*Windows Server*") {
                                Uninstall-WindowsFeature $Name
                            }
                        }
                        catch {
                            Write-Host $_.Exception.Message -ForegroundColor Red -BackgroundColor Black
                        }
                    }
                    "PowerShell Module" {
                        if (!$Silent) { Write-Host "Removing PowerShell Module $Name" -ForegroundColor Green -BackgroundColor Black }
                        try {
                            Uninstall-Module $Name
                        }
                        catch {
                            Write-Host $.Exception.Message -ForegroundColor Red -BackgroundColor Black
                        }
                    }
                    ".NET Framework" {
                        if (!$Silent) { Write-Host "Removing .NET Framework $Name" -ForegroundColor Green -BackgroundColor Black }
                        try {
                            Remove-WindowsCapability -Online -Name $Name
                        }
                        catch {
                            Write-Host $.Exception.Message -ForegroundColor Red -BackgroundColor Black
                        }
                    }
                    "Java Package" {
                        if (!$Silent) { Write-Host "Removing Java $Name" -ForegroundColor Green -BackgroundColor Black }
                        try {
                            if ($Source) {
                                $JavaInstallerPath = $Source + "\java.msi"
                                if (Test-Path $JavaInstallerPath) {
                                    Start-Process -FilePath "msiexec.exe" -ArgumentList "/x $JavaInstallerPath /qn" -Wait
                                }
                                else {
                                    Write-Host "Error: Java installer not found at $JavaInstallerPath" -ForegroundColor Red -BackgroundColor Black
                                }
                            }
                            else {
                                $javaPath = Get-ChildItem 'C:\Program Files\Java' -Directory | Select-Object -First 1
                                if ($null -ne $javaPath) {
                                    $uninstallString = "$javaPath\uninstall\jre-uninstall.exe"
                                    if (Test-Path $uninstallString) {
                                        Start-Process -FilePath $uninstallString -ArgumentList '/s' -Wait
                                        Write-Host "Java has been removed successfully using the default method." -ForegroundColor Green -BackgroundColor Black
                                    }
                                    else {
                                        Write-Host "Error: The uninstaller for Java was not found at $uninstallString" -ForegroundColor Red -BackgroundColor Black
                                    }
                                }
                                else {
                                    Write-Host "Java is not installed on this machine." -ForegroundColor Red -BackgroundColor Black
                                }
                            }
                        }
                        catch {
                            Write-Host $_.Exception.Message -ForegroundColor Red -BackgroundColor Black
                        }
                    }
                    "Chocolatey Package" {
                        if (!$Silent) { Write-Host "Removing Chocolatey Package $Name" -ForegroundColor Green -BackgroundColor Black }
                        try {
                            choco uninstall $Name
                        }
                        catch {
                            Write-Host $.Exception.Message -ForegroundColor Red -BackgroundColor Black
                        }
                    }
                    "Software Package" {
                        if (!$Silent) { Write-Host "Removing Software Package $Name" -ForegroundColor Green -BackgroundColor Black }
                        try {
                            if ($Name -contains ".msi") {
                                Write-Host "Removing Windows Installer Package $Name"
                                Start-Process "msiexec.exe" -ArgumentList "/x $Name /qn" -Wait
                            }
                            elseif ($Name -contains ".exe") {
                                Write-Host "Removing Executable Package $Name"
                                Start-Process $Name -ArgumentList "/uninstall /quiet" -Wait
                            }
                            elseif ($Name -contains ".appxbundle") {
                                Write-Host "Removing Appx Bundle Package $Name"
                                Remove-AppxPackage -Package $Name
                            }
                            elseif ($Name -contains ".cab") {
                                Write-Host "Removing Cabinet Package $Name"
                                if ($WinVer.Major -ge 10) {
                                    Remove-WindowsPackage -Online -PackageName $Name -NoRestart -Verbose
                                }
                                elseif ($WinVer.Major -eq 6) {
                                    $GetCabPath = (Get-ChildItem -Path $env:SystemDrive -Filter $Name -Recurse).DirectoryName
                                    Start-Process cmd -ArgumentList "/c $env:windir\System32\dism.exe /Online /Add-Package /PackagePath:$GetCabPath /NoRestart" -WindowStyle Minimized
                                }
                            }
                            else {
                                Write-Host "Removing Control Panel Package $Name"
                                Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -eq $Name } | ForEach-Object { $_.Uninstall() }
                            }            
                        }
                        catch {
                            Write-Host $_.Exception.Message -ForegroundColor Red -BackgroundColor Black
                        }
                    }
                    "AppxProvisioned Package" {
                        if (!$Silent) { Write-Host "Removing Software Package $Name" -ForegroundColor Green -BackgroundColor Black }
                        try {
                            Remove-AppxProvisionedPackage -PackageName $Name -Online
                        }
                        catch {
                            Write-Host $_.Exception.Message -ForegroundColor Red -BackgroundColor Black
                        }
                    }
                }
            }
        }
    }
    END {
        if (!$Silent) {
            Write-Verbose -Message "Installation process completed."
        }
        if ($Restart) {
            Clear-History -Verbose
            Write-Warning "Restarting computer in $RestartTime seconds!"
            $Lenght = $RestartTime / 100
            for ($RestartTime; $RestartTime -gt -1; $RestartTime--) {
                $Time = [int](([string]($RestartTime / 60)).Split('.')[0])
                Write-Progress -Activity "Restarting in..." -Status "$Time minutes $RestartTime seconds left" -PercentComplete ($RestartTime / $Lenght)
                Start-Sleep -Seconds 1
            }
            Restart-Computer -Force
        }
    }
}