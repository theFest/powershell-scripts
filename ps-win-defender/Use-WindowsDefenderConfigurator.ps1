Function Use-WindowsDefenderConfigurator {
    <#
    .SYNOPSIS
    Configure Windows Defender preferences.

    .DESCRIPTION
    This function configures various preferences for Windows Defender, including network protection, archive scanning, behavior monitoring, and more.

    .PARAMETER CsvPath
    Path to a CSV file containing configuration settings. Default is ".\Bootstrap-MicrosoftDefenderConfiguration.csv".
    .PARAMETER Force
    Forces the operation to complete without asking for confirmation.
    .PARAMETER EnableNetworkProtection
    Network protection helps to prevent employees from using any application to access dangerous domains that may host phishing scams, exploits, and other malicious content on the Internet.
    .PARAMETER EnableControlledFolderAccess
    Controlled folder access helps you protect valuable data from malicious apps and threats, such as ransomware.
    .PARAMETER SignatureScheduleDay
    Specifies the day of the week to schedule signature updates, default is "Everyday".
    .PARAMETER SignatureScheduleTime
    Specifies the time of day, as the number of minutes after midnight, to check for definition updates.
    .PARAMETER DisableArchiveScanning
    Disables scanning of archive files for malicious and unwanted software.
    .PARAMETER DisableAutoExclusions
    Disables automatic exclusions for the server.
    .PARAMETER DisableBehaviorMonitoring
    Disables behavior monitoring.
    .PARAMETER DisableBlockAtFirstSeen
    Disables blocking at first seen.
    .PARAMETER DisableCatchupFullScan
    Disables catch-up scans for scheduled full scans.
    .PARAMETER DisableCatchupQuickScan
    Disables catch-up scans for scheduled quick scans.
    .PARAMETER DisableEmailScanning
    Disables scanning of email attachments.
    .PARAMETER DisableIOAVProtection
    Disables IOAV protection for downloaded files.
    .PARAMETER DisableIntrusionPreventionSystem
    Disables the intrusion prevention system.
    .PARAMETER DisablePrivacyMode
    Disables privacy mode to prevent non-administrators from displaying threat history.
    .PARAMETER DisableRealtimeMonitoring
    Disables real-time monitoring.
    .PARAMETER CheckForSignaturesBeforeRunningScan
    Enables checking for signatures before running a scan.
    .PARAMETER DisableRemovableDriveScanning
    Disables scanning of removable drives during full scans.
    .PARAMETER DisableRestorePoint
    Disables scanning of restore points.
    .PARAMETER DisableScanningMappedNetworkDrivesForFullScan
    Disables scanning of mapped network drives during full scans.
    .PARAMETER DisableScanningNetworkFiles
    Disables scanning of network files.
    .PARAMETER DisableScriptScanning
    Disables scanning of scripts during malware scans.
    .PARAMETER HighThreatDefaultAction
    Specifies the default action for high-level threats.
    .PARAMETER LowThreatDefaultAction
    Specifies the default action for low-level threats.
    .PARAMETER ModerateThreatDefaultAction
    Specifies the default action for moderate-level threats.
    .PARAMETER PUAProtection
    Enables or disables protection against potentially unwanted applications.
    .PARAMETER QuarantinePurgeItemsAfterDelay
    Number of days to keep items in the quarantine folder.
    .PARAMETER RandomizeScheduleTaskTimes
    Specifies whether to randomize scheduled task times.
    .PARAMETER RealTimeScanDirection
    Scanning configuration for incoming and outgoing files on NTFS volumes.
    .PARAMETER RemediationScheduleDay
    Day of the week to perform scheduled remediation scans.
    .PARAMETER RemediationScheduleTime
    Time of day to perform scheduled remediation scans.
    .PARAMETER ReportingAdditionalActionTimeOut
    Timeout for additional actions on detections.
    .PARAMETER ReportingCriticalFailureTimeOut
    Timeout for critical failures on detections.
    .PARAMETER ReportingNonCriticalTimeOut
    Timeout for non-critical failures on detections.
    .PARAMETER ScanAvgCPULoadFactor
    Maximum percentage CPU usage for a scan.
    .PARAMETER ScanOnlyIfIdleEnabled
    Start scheduled scans only when the computer is not in use.
    .PARAMETER ScanParameters
    Scan type to use during a scheduled scan.
    .PARAMETER ScanPurgeItemsAfterDelay
    Number of days to keep items in the scan history folder.
    .PARAMETER ScanScheduleDay
    Day of the week to perform scheduled scans.
    .PARAMETER ScanScheduleQuickScanTime
    Time of day to perform scheduled quick scans.
    .PARAMETER ScanScheduleTime
    Time of day to perform scheduled scans.
    .PARAMETER SevereThreatDefaultAction
    Default action for severe threats.
    .PARAMETER SignatureAuGracePeriod
    Grace period for signature updates.
    .PARAMETER SignatureDisableUpdateOnStartupWithoutEngine
    Initiate definition updates even if no antimalware engine is present.
    .PARAMETER SignatureFirstAuGracePeriod
    Grace period for the first signature update.
    .PARAMETER SignatureUpdateCatchupInterval
    Interval for catch-up definition updates.
    .PARAMETER SignatureUpdateInterval
    Interval for regular definition updates.
    .PARAMETER SubmitSamplesConsent
    Specifies how Windows Defender checks for user consent for certain samples.
    .PARAMETER MAPSReporting
    Membership in Microsoft Active Protection Service.
    .PARAMETER ThrottleLimit
    Maximum number of concurrent operations.
    .PARAMETER UILockdown
    Specifies whether to disable UI lockdown mode.
    .PARAMETER UnknownThreatDefaultAction
    Default action for unknown threats.
    .PARAMETER SignatureFallbackOrder
    Order in which to contact different definition update sources.

    .EXAMPLE
    Use-WindowsDefenderConfigurator -Force -Verbose

    .NOTES
    v0.0.1
    #>
    [CmdletBinding(ConfirmImpact = "Low", SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Path to the CSV file")]
        [string]$CsvPath = ".\Bootstrap-MicrosoftDefenderConfiguration.csv",
        
        [Parameter(Mandatory = $false, HelpMessage = "Forces the operation")]
        [switch]$Force,
        
        [Parameter(Mandatory = $false, HelpMessage = "Enables network protection to prevent access to dangerous domains")]
        [ValidateSet("Enabled", "Disabled")]
        [string]$EnableNetworkProtection = "Enabled",
        
        [Parameter(Mandatory = $false, HelpMessage = "Enables controlled folder access to protect valuable data from malicious apps and threats")]
        [ValidateSet("Enabled", "Disabled")]
        [string]$EnableControlledFolderAccess = "Enabled",

        [Parameter(Mandatory = $false, HelpMessage = "Day for signature schedule")]
        [ValidateSet("Everyday", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday")]
        [string]$SignatureScheduleDay = "Everyday",

        [Parameter(Mandatory = $false, HelpMessage = "Time of day to schedule signature updates")]
        [ValidateRange(0, 2359)]
        [int]$SignatureScheduleTime = 165,
        
        [Parameter(Mandatory = $false, HelpMessage = "Disables scanning of archive files for malicious software")]
        [bool]$DisableArchiveScanning = $true,
        
        [Parameter(Mandatory = $false, HelpMessage = "Disables automatic exclusions")]
        [bool]$DisableAutoExclusions = $false,
        
        [Parameter(Mandatory = $false, HelpMessage = "Disables behavior monitoring")]
        [bool]$DisableBehaviorMonitoring = $true,
        
        [Parameter(Mandatory = $false, HelpMessage = "Disables block at first seen")]
        [bool]$DisableBlockAtFirstSeen = $true,
        
        [Parameter(Mandatory = $false, HelpMessage = "Disables catch-up full scan")]
        [bool]$DisableCatchupFullScan = $true,
        
        [Parameter(Mandatory = $false, HelpMessage = "Disables catch-up quick scan")]
        [bool]$DisableCatchupQuickScan = $true,
        
        [Parameter(Mandatory = $false, HelpMessage = "Disables email scanning")]
        [bool]$DisableEmailScanning = $false,
        
        [Parameter(Mandatory = $false, HelpMessage = "Disables IOAV protection")]
        [bool]$DisableIOAVProtection = $true,
        
        [Parameter(Mandatory = $false, HelpMessage = "Disables intrusion prevention system")]
        [bool]$DisableIntrusionPreventionSystem = $false,
        
        [Parameter(Mandatory = $false, HelpMessage = "Disables privacy mode")]
        [bool]$DisablePrivacyMode = $false,
        
        [Parameter(Mandatory = $false, HelpMessage = "Disables real-time monitoring")]
        [bool]$DisableRealtimeMonitoring = $false,
        
        [Parameter(Mandatory = $false, HelpMessage = "Sets the number of signatures to check before running a scan")]
        [int]$CheckForSignaturesBeforeRunningScan = 1,
        
        [Parameter(Mandatory = $false, HelpMessage = "Disables removable drive scanning")]
        [bool]$DisableRemovableDriveScanning = $true,
        
        [Parameter(Mandatory = $false, HelpMessage = "Disables restore point")]
        [bool]$DisableRestorePoint = $true,
        
        [Parameter(Mandatory = $false, HelpMessage = "Disables scanning mapped network drives for full scan")]
        [bool]$DisableScanningMappedNetworkDrivesForFullScan = $true,
        
        [Parameter(Mandatory = $false, HelpMessage = "Disables scanning network files")]
        [bool]$DisableScanningNetworkFiles = $false,
        
        [Parameter(Mandatory = $false, HelpMessage = "Disables script scanning")]
        [bool]$DisableScriptScanning = $false,
        
        [Parameter(Mandatory = $false, HelpMessage = "Default action for high-threat items")]
        [ValidateSet("Quarantine", "Remove", "NoAction")]
        [string]$HighThreatDefaultAction = "Quarantine",
        
        [Parameter(Mandatory = $false, HelpMessage = "Default action for low-threat items")]
        [ValidateSet("Block", "Quarantine", "Remove", "NoAction")]
        [string]$LowThreatDefaultAction = "Block",
        
        [Parameter(Mandatory = $false, HelpMessage = "Default action for moderate-threat items")]
        [ValidateSet("Quarantine", "Remove", "NoAction")]
        [string]$ModerateThreatDefaultAction = "Quarantine",
        
        [Parameter(Mandatory = $false, HelpMessage = "Enables PUA (Potentially Unwanted Applications) protection")]
        [ValidateSet("Enabled", "Disabled")]
        [string]$PUAProtection = "Enabled",
        
        [Parameter(Mandatory = $false, HelpMessage = "Number of days to purge items from quarantine")]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$QuarantinePurgeItemsAfterDelay = 30,
        
        [Parameter(Mandatory = $false, HelpMessage = "Enables randomizing scheduled task times")]
        [bool]$RandomizeScheduleTaskTimes = $true,
        
        [Parameter(Mandatory = $false, HelpMessage = "Real-time scan direction")]
        [ValidateRange(0, 1)]
        [int]$RealTimeScanDirection = 0,
        
        [Parameter(Mandatory = $false, HelpMessage = "Day for remediation schedule")]
        [ValidateSet("Everyday", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday")]
        [string]$RemediationScheduleDay = "Everyday",
        
        [Parameter(Mandatory = $false, HelpMessage = "Time for remediation schedule")]
        [ValidateRange(0, 2359)]
        [int]$RemediationScheduleTime = 120,
        
        [Parameter(Mandatory = $false, HelpMessage = "Time-out period for additional action reporting")]
        [int]$ReportingAdditionalActionTimeOut = 10080,
        
        [Parameter(Mandatory = $false, HelpMessage = "Time-out period for critical failure reporting")]
        [int]$ReportingCriticalFailureTimeOut = 10080,
        
        [Parameter(Mandatory = $false, HelpMessage = "Time-out period for non-critical reporting")]
        [int]$ReportingNonCriticalTimeOut = 11440,
        
        [Parameter(Mandatory = $false, HelpMessage = "CPU load factor for scan")]
        [ValidateRange(0, 100)]
        [int]$ScanAvgCPULoadFactor = 50,
        
        [Parameter(Mandatory = $false, HelpMessage = "Enables scan only if the system is idle")]
        [bool]$ScanOnlyIfIdleEnabled = $true,
        
        [Parameter(Mandatory = $false, HelpMessage = "Specifies the scan parameters")]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$ScanParameters = 1,
        
        [Parameter(Mandatory = $false, HelpMessage = "Number of days to purge items after scan")]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$ScanPurgeItemsAfterDelay = 15,
        
        [Parameter(Mandatory = $false, HelpMessage = "Day for scan schedule")]
        [ValidateSet("Everyday", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday")]
        [string]$ScanScheduleDay = "Everyday",
        
        [Parameter(Mandatory = $false, HelpMessage = "Time for quick scan schedule")]
        [ValidateRange(0, 2359)]
        [int]$ScanScheduleQuickScanTime = 0,
        
        [Parameter(Mandatory = $false, HelpMessage = "Time for scan schedule")]
        [ValidateRange(0, 2359)]
        [int]$ScanScheduleTime = 120,
        
        [Parameter(Mandatory = $false, HelpMessage = "Default action for severe-threat items")]
        [ValidateSet("Quarantine", "Remove", "NoAction")]
        [string]$SevereThreatDefaultAction = "Quarantine",
        
        [Parameter(Mandatory = $false, HelpMessage = "Grace period for signature auto-update")]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$SignatureAuGracePeriod = 0,
        
        [Parameter(Mandatory = $false, HelpMessage = "Disables signature update on startup without engine")]
        [bool]$SignatureDisableUpdateOnStartupWithoutEngine = $false,
        
        [Parameter(Mandatory = $false, HelpMessage = "First automatic update grace period")]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$SignatureFirstAuGracePeriod = 120,
        
        [Parameter(Mandatory = $false, HelpMessage = "Interval for signature update catch-up")]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$SignatureUpdateCatchupInterval = 1,
        
        [Parameter(Mandatory = $false, HelpMessage = "Interval for signature update")]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$SignatureUpdateInterval = 12,
        
        [Parameter(Mandatory = $false, HelpMessage = "Consent for submitting samples")]
        [ValidateSet("AlwaysPrompt", "SendSafeSamplesAutomatically", "NeverSendData")]
        [string]$SubmitSamplesConsent = "AlwaysPrompt",
        
        [Parameter(Mandatory = $false, HelpMessage = "Reporting level for MAPS")]
        [ValidateSet("None", "Basic", "Advanced")]
        [string]$MAPSReporting = "Advanced",
        
        [Parameter(Mandatory = $false, HelpMessage = "Specifies the throttle limit")]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$ThrottleLimit = 0,
        
        [Parameter(Mandatory = $false, HelpMessage = "Enables UI lockdown")]
        [bool]$UILockdown = $false,
        
        [Parameter(Mandatory = $false, HelpMessage = "Default action for unknown threat items")]
        [ValidateSet("Block", "NoAction")]
        [string]$UnknownThreatDefaultAction = "Block",
        
        [Parameter(Mandatory = $false, HelpMessage = "Signature fallback order")]
        [ValidateSet("MicrosoftUpdateServer", "MMPC")]
        [string]$SignatureFallbackOrder = "MicrosoftUpdateServer | MMPC"
    )
    BEGIN {
        Start-Transcript -Path "$env:TEMP\MicrosoftDefenderConfigurator.txt" -Force -Verbose
        Write-Verbose -Message "Starting Microsoft Defender Configuration Process..."
        $StartTime = Get-Date
        $AttackSurfaceReductionRuleList = @()
        if (Test-Path -Path $CsvPath -ErrorAction SilentlyContinue) {
            Write-Verbose -Message "Importing attack surface reduction settings from '$CsvPath'..."
            $AttackSurfaceReductionRuleList = Import-Csv -Path $CsvPath -Delimiter ',' -Encoding UTF8 -Verbose
        }
        else {
            Write-Verbose -Message "Using default attack surface reduction settings..."
            $RuleDefaults = @'
RuleID,RuleDescription,RuleAction
75668C1F-73B5-4CF0-BB93-3ECF5CB7CC84,Block Office applications from injecting into other processes,Enabled
3B576869-A4EC-4529-8536-B80A7769E899,Block Office applications from creating executable content,Enabled
D4F940AB-401B-4EfC-AADC-AD5F3C50688A,Block Office applications from creating child processes,Enabled
D3E037E1-3EB8-44C8-A917-57927947596D,Impede JavaScript and VBScript to launch executable,Enabled
5BEB7EFE-FD9A-4556-801D-275E5FFC04CC,Block execution of potentially obfuscated script,Enabled
BE9BA2D9-53EA-4CDC-84E5-9B1EEEE46550,Block executable content from email client and webmail,Enabled
92E97FA1-2EDF-4476-BDD6-9DD0B4DDDC7B,Block Win32 imports from Macro code in Office,Enabled
c1db55ab-c21a-4637-bb3f-a12568109d35,Use advanced protection against ransomware,Enabled
9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2,Block credential stealing from the Windows local security authority subsystem (lsass.exe),Enabled
d1e49aac-8f56-4280-b9ba-993a6d77406c,Block process creations originating from PSExec and WMI commands,Enabled
b2b3f03d-6a65-4f7b-a9c7-1c7ef74a9ba4,Block untrusted and unsigned processes that run from USB,Enabled
A4806A-3B50-4701-A248-26504D7A9C47,Block untrusted and unsigned processes that run from network,Enabled
26190899-1602-49e8-8b27-eb1d0a1ce869, Block Office communication applications from creating child processes, AuditMode
7674ba52-37eb-4a4f-a9a1-f0f9a1619a2c, Block Adobe Reader from creating child processes, Enabled
e6db77e5-3df2-4cf1-b95a-636979351e5b, Block persistence through WMI event subscription, Enabled
01443614-cd74-433a-b99e-2ecdc07bfc25, Block executable files from running unless they meet a prevalence age or trusted list criteria, AuditMode
'@
            $AttackSurfaceReductionRuleList = ConvertFrom-Csv -InputObject $RuleDefaults -Delimiter ',' -Verbose
        }
    }
    PROCESS {
        $Parameters = @(
            "EnableNetworkProtection",
            "EnableControlledFolderAccess",
            "DisableArchiveScanning",
            "DisableAutoExclusions",
            "DisableBehaviorMonitoring",
            "DisableBlockAtFirstSeen",
            "DisableCatchupFullScan",
            "DisableCatchupQuickScan",
            "DisableEmailScanning",
            "DisableIOAVProtection",
            "DisableIntrusionPreventionSystem",
            "DisablePrivacyMode",
            "DisableRealtimeMonitoring",
            "CheckForSignaturesBeforeRunningScan",
            "DisableRemovableDriveScanning",
            "DisableRestorePoint",
            "DisableScanningMappedNetworkDrivesForFullScan",
            "DisableScanningNetworkFiles",
            "DisableScriptScanning",
            "HighThreatDefaultAction",
            "LowThreatDefaultAction",
            "ModerateThreatDefaultAction",
            "PUAProtection",
            "QuarantinePurgeItemsAfterDelay",
            "RandomizeScheduleTaskTimes",
            "RealTimeScanDirection",
            "RemediationScheduleDay",
            "RemediationScheduleTime",
            "ReportingAdditionalActionTimeOut",
            "ReportingCriticalFailureTimeOut",
            "ReportingNonCriticalTimeOut",
            "ScanAvgCPULoadFactor",
            "ScanOnlyIfIdleEnabled",
            "ScanParameters",
            "ScanPurgeItemsAfterDelay",
            "ScanScheduleDay",
            "ScanScheduleQuickScanTime",
            "ScanScheduleTime",
            "SevereThreatDefaultAction",
            "SignatureAuGracePeriod",
            "SignatureDisableUpdateOnStartupWithoutEngine",
            "SignatureFirstAuGracePeriod",
            "SignatureScheduleDay",
            "SignatureScheduleTime",
            "SignatureUpdateCatchupInterval",
            "SignatureUpdateInterval",
            "SubmitSamplesConsent",
            "MAPSReporting",
            "ThrottleLimit",
            "UILockdown",
            "UnknownThreatDefaultAction",
            "SignatureFallbackOrder"
        )
        $ParameterHashtable = @{}
        Write-Verbose -Message "Iterating over the parameters and populate the hashtable..."
        foreach ($Parameter in $Parameters) {
            $ParamValue = Get-Variable -Name $Parameter -ValueOnly -ErrorAction SilentlyContinue
            if ($null -ne $ParamValue) {
                $ParameterHashtable[$Parameter] = $ParamValue
            }
        }
        Write-Verbose -Message "Calling Set-MpPreference with the populated hashtable..."
        Set-MpPreference @ParameterHashtable -Force -ErrorAction Continue -Verbose
        $NewControlledFolderAccessAllowedApplications = @("$env:windir\System32\taskhostw.exe")
        $AllControlledFolderAccessAllowedApplications = (New-Object -TypeName System.Collections.Generic.List[System.Object])
        $AllControlledFolderAccessAllowedApplications.Add((Get-MpPreference -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ControlledFolderAccessAllowedApplications))
        foreach ($NewControlledFolderAccessAllowedApplication in $NewControlledFolderAccessAllowedApplications) {
            if ($AllControlledFolderAccessAllowedApplications -notcontains $NewControlledFolderAccessAllowedApplication) {
                Write-Verbose -Message "Adding $($NewControlledFolderAccessAllowedApplication) to the Controlled Folder Access Allowed Applications list..."
                $AllControlledFolderAccessAllowedApplications.Add($NewControlledFolderAccessAllowedApplication)
            }
        }
        $AllControlledFolderAccessAllowedApplications = ($AllControlledFolderAccessAllowedApplications | Sort-Object -Unique)
        Write-Verbose -Message "Apply the new Controlled Folder Access Allowed Applications list..."
        Set-MpPreference -ControlledFolderAccessAllowedApplications $AllControlledFolderAccessAllowedApplications -Force -ErrorAction Continue -Verbose
        $NewExclusionPathList = @(
            "$env:windir\SoftwareDistribution\DataStore\Datastore.edb",
            "$env:windir\SoftwareDistribution\DataStore\Logs\Edb*.jrs",
            "$env:windir\SoftwareDistribution\DataStore\Logs\Edb.chk",
            "$env:windir\SoftwareDistribution\DataStore\Logs\Tmp.edb",
            "$env:windir\Security\Database\*.edb",
            "$env:windir\Security\Database\*.sdb",
            "$env:windir\Security\Database\*.log",
            "$env:windir\Security\Database\*.chk",
            "$env:windir\Security\Database\*.jrs",
            "$env:windir\Security\Database\*.xml",
            "$env:windir\Security\Database\*.csv",
            "$env:windir\Security\Database\*.cmtx",
            "$env:ProgramData\ntuser.pol",
            "$env:windir\System32\GroupPolicy\Machine\Registry.pol",
            "$env:windir\System32\GroupPolicy\Machine\Registry.tmp",
            "$env:windir\System32\GroupPolicy\User\Registry.pol",
            "$env:windir\System32\GroupPolicy\User\Registry.tmp"
        )
        $AllExclusionPath = (New-Object -TypeName System.Collections.Generic.List[System.Object])
        $AllExclusionPath.Add((Get-MpPreference -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ExclusionPath))
        foreach ($NewExclusionPath in $NewExclusionPathList) {
            if ($AllExclusionPath -notcontains $NewExclusionPath) {
                Write-Verbose -Message "Adding $($NewExclusionPath) as a path to exclude..."
                $AllExclusionPath.Add($NewExclusionPath)
            }
        }
        $AllExclusionPath = ($AllExclusionPath | Sort-Object -Unique)
        Write-Verbose -Message "Apply the new Path to exclude list"
        Set-MpPreference -ExclusionPath $AllExclusionPath -Force -ErrorAction Continue -Verbose
        $NewExclusionProcessList = @(
            "$env:windir\System32\svchost.exe",
            "$env:windir\System32\wuauclt.exe"
        )
        $AllExclusionProcess = (New-Object -TypeName System.Collections.Generic.List[System.Object])
        $AllExclusionProcess.Add((Get-MpPreference -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ExclusionProcess))
        foreach ($NewExclusionProcess in $NewExclusionProcessList) {
            if ($AllExclusionProcess -notcontains $NewExclusionProcess) {
                Write-Verbose -Message "Adding $($NewExclusionProcess) as a process to exclude..."
                $AllExclusionProcess.Add($NewExclusionProcess)
            }
        }
        $AllExclusionProcess = ($AllExclusionProcess | Sort-Object -Unique)
        Write-Verbose -Message "Apply the new Process to exclude list"
        Set-MpPreference -ExclusionProcess $AllExclusionProcess -Force -ErrorAction Continue -Verbose
        $ProcessMitigationFile = ".\ProcessMitigation.xml"
        if (-not (Test-Path -Path $ProcessMitigationFile -ErrorAction SilentlyContinue)) {
            $ProcessMitigationUri = "https://demo.wd.microsoft.com/Content/ProcessMitigation.xml"
            Write-Verbose -Message "Downloading Process Mitigation file from $($ProcessMitigationUri)..."
            Invoke-WebRequest -Uri $ProcessMitigationUri -OutFile $ProcessMitigationFile -Method Get -ContentType 'text/xml' -ErrorAction Continue -Verbose
        }
        if (Test-Path -Path $ProcessMitigationFile -ErrorAction SilentlyContinue) {
            Write-Verbose -Message "Enabling Exploit Protection..."
            Set-ProcessMitigation -PolicyFilePath $ProcessMitigationFile -ErrorAction Continue -Verbose
            Remove-Item -Path $ProcessMitigationFile -Force -Confirm:$false -ErrorAction SilentlyContinue -Verbose
        }
        else {
            Write-Warning -Message "The local Process Mitigation file ('$ProcessMitigationFile') is missing, not enabling Exploit Protection!"
        }
        Write-Verbose -Message "Turning on Windows Defender Sandbox..."
        [Environment]::SetEnvironmentVariable('MP_FORCE_USE_SANDBOX', 1, 'Machine')
        $AttackSurfaceReductionRulesIds = (Get-MpPreference -ErrorAction SilentlyContinue | Select-Object -ExpandProperty AttackSurfaceReductionRules_Ids)
        Write-Verbose -Message "Enabling Attack Surface Reduction rules..."
        $AddMpPreferenceParameters = @{
            ErrorAction = 'Stop'
            Force       = $true
        }
        foreach ($AttackSurfaceReductionRule in $AttackSurfaceReductionRuleList) {
            try {
                if (($Force) -or ($AttackSurfaceReductionRulesIds -notcontains $AttackSurfaceReductionRule.RuleID)) {
                    Write-Verbose -Message "Set $($AttackSurfaceReductionRule.RuleDescription) to $($AttackSurfaceReductionRule.RuleAction)"
                    $AddMpPreferenceParameters.AttackSurfaceReductionRules_Ids = $AttackSurfaceReductionRule.RuleID
                    $AddMpPreferenceParameters.AttackSurfaceReductionRules_Actions = $AttackSurfaceReductionRule.RuleAction
                    Add-MpPreference @AddMpPreferenceParameters -Verbose
                }
            }
            catch {
                Write-Error -Message $_.Exception.Message -ErrorAction Stop
                Write-Warning -Message "Unable to enable Rule: $($AttackSurfaceReductionRule.RuleID) - $($AttackSurfaceReductionRule.RuleDescription)"
            }
        }
        & "$env:windir\system32\rundll32.exe" USER32.DLL, UpdatePerUserSystemParameters , 1 , True
        Write-Warning -Message "Enabling Windows Firewall for all Profiles --> set the default to block everything!"
        Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled True -DefaultInboundAction Block -LogBlocked True -Confirm:$false -ErrorAction Continue -Verbose
    }
    END {
        Write-Host "Updating Windows Defender signatures..." -ForegroundColor Cyan
        Update-MpSignature -ErrorAction SilentlyContinue -Verbose
        $EndTime = Get-Date
        $Duration = New-TimeSpan -Start $StartTime -End $EndTime
        Write-Verbose "Microsoft Defender Configuration Process Completed. Time taken: $($Duration.ToString())"
        Stop-Transcript
    }
}
