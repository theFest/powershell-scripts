function Reset-WindowsUpdateComponents {
    <#
    .SYNOPSIS
    Resets Windows Update components. 

    .DESCRIPTION
    This function manages Windows Update components on either the local computer or a remote computer, by stopping and starting services optionally clearing update-related folders and cache.

    .EXAMPLE
    Reset-WindowsUpdateComponents -StopServices -RemoveSoftwareDistribution -RemoveInetCache -StartServices -Verbose
    Reset-WindowsUpdateComponents -StopServices -RemoveSoftwareDistribution -RemoveInetCache -StartServices -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass"

    .NOTES
    v0.3.8
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium")]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Stops the Windows Update services")]
        [switch]$StopServices,

        [Parameter(Mandatory = $false, HelpMessage = "Removes the contents of the SoftwareDistribution folder")]
        [switch]$RemoveSoftwareDistribution,

        [Parameter(Mandatory = $false, HelpMessage = "Removes the Internet Cache used by the system profile")]
        [switch]$RemoveInetCache,

        [Parameter(Mandatory = $false, HelpMessage = "Starts the Windows Update services (wuauserv, cryptSvc, bits, msiserver)")]
        [switch]$StartServices,

        [Parameter(Mandatory = $false, HelpMessage = "Hostname of the remote computer, if not provided, will run on the local computer")]
        [string]$ComputerName,

        [Parameter(Mandatory = $false, HelpMessage = "Username for the remote connection, required if `ComputerName` is specified")]
        [string]$User,

        [Parameter(Mandatory = $false, HelpMessage = "Password for the remote connection, required if `ComputerName` is specified")]
        [string]$Pass
    )
    $Summary = @{
        ServicesStopped             = $false
        SoftwareDistributionRemoved = $false
        InetCacheRemoved            = $false
        ServicesStarted             = $false
        ActionsSkipped              = @()
        Errors                      = @()
        RemovedFiles                = @()
    }
    $ResetComponentsScriptBlock = {
        param ($StopServices, $RemoveSoftwareDistribution, $RemoveInetCache, $StartServices)
        $LocalSummary = @{
            ServicesStopped             = $false
            SoftwareDistributionRemoved = $false
            InetCacheRemoved            = $false
            ServicesStarted             = $false
            ActionsSkipped              = @()
            Errors                      = @()
            RemovedFiles                = @()
        }
        if ($StopServices) {
            try {
                Stop-Service -Name wuauserv, cryptSvc, bits, msiserver -Force -ErrorAction Stop
                Write-Verbose -Message "Stopped Windows Update services."
                $LocalSummary.ServicesStopped = $true
            }
            catch {
                $LocalSummary.Errors += "Failed to stop services: $_"
            }
        }
        else {
            $LocalSummary.ActionsSkipped += "Stopping services skipped."
        }
        if ($RemoveSoftwareDistribution) {
            try {
                $Items = Get-ChildItem -Path "$env:SystemRoot\SoftwareDistribution\*" -Recurse -ErrorAction Stop
                foreach ($Item in $Items) {
                    Remove-Item -Path $Item.FullName -Force -Verbose -ErrorAction Stop
                    if ($PSCmdlet.MyInvocation.BoundParameters["Verbose"]) {
                        Write-Verbose "Removed: $($Item.FullName)"
                    }
                    $LocalSummary.RemovedFiles += $Item.FullName
                }
                Write-Verbose "Removed contents of the SoftwareDistribution folder."
                $LocalSummary.SoftwareDistributionRemoved = $true
            }
            catch {
                $LocalSummary.Errors += "Failed to remove SoftwareDistribution folder: $_"
            }
        }
        else {
            $LocalSummary.ActionsSkipped += "Removing SoftwareDistribution folder skipped."
        }
        if ($RemoveInetCache) {
            try {
                $Items = Get-ChildItem -Path "$env:SystemRoot\System32\config\systemprofile\AppData\Local\Microsoft\Windows\INetCache\*" -Recurse -ErrorAction Stop
                foreach ($Item in $Items) {
                    Remove-Item -Path $Item.FullName -Force -Verbose -ErrorAction Stop
                    if ($PSCmdlet.MyInvocation.BoundParameters["Verbose"]) {
                        Write-Verbose "Removed: $($Item.FullName)"
                    }
                    $LocalSummary.RemovedFiles += $Item.FullName
                }
                Write-Verbose "Removed Internet Cache."
                $LocalSummary.InetCacheRemoved = $true
            }
            catch {
                $LocalSummary.Errors += "Failed to remove Internet Cache: $_"
            }
        }
        else {
            $LocalSummary.ActionsSkipped += "Removing Internet Cache skipped."
        }
        if ($StartServices) {
            try {
                Start-Service -Name wuauserv, cryptSvc, bits, msiserver -ErrorAction Stop
                Write-Verbose "Started Windows Update services."
                $LocalSummary.ServicesStarted = $true
            }
            catch {
                $LocalSummary.Errors += "Failed to start services: $_"
            }
        }
        else {
            $LocalSummary.ActionsSkipped += "Starting services skipped."
        }
        return $LocalSummary
    }
    if ($ComputerName) {
        if ($PSCmdlet.ShouldProcess($ComputerName, "Reset Windows Update Components")) {
            $Credential = New-Object System.Management.Automation.PSCredential ($User, (ConvertTo-SecureString $Pass -AsPlainText -Force))
            $SessionOptions = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck
            $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential -SessionOption $SessionOptions
            try {
                $RemoteSummary = Invoke-Command -Session $Session -ScriptBlock $ResetComponentsScriptBlock -ArgumentList $StopServices, $RemoveSoftwareDistribution, $RemoveInetCache, $StartServices
                $Summary.ServicesStopped = $RemoteSummary.ServicesStopped
                $Summary.SoftwareDistributionRemoved = $RemoteSummary.SoftwareDistributionRemoved
                $Summary.InetCacheRemoved = $RemoteSummary.InetCacheRemoved
                $Summary.ServicesStarted = $RemoteSummary.ServicesStarted
                $Summary.ActionsSkipped += $RemoteSummary.ActionsSkipped
                $Summary.Errors += $RemoteSummary.Errors
                $Summary.RemovedFiles += $RemoteSummary.RemovedFiles
            }
            finally {
                Remove-PSSession -Session $Session -Verbose
            }
        }
    }
    else {
        if ($PSCmdlet.ShouldProcess("localhost", "Reset Windows Update Components")) {
            $Summary = & $ResetComponentsScriptBlock -StopServices:$StopServices -RemoveSoftwareDistribution:$RemoveSoftwareDistribution -RemoveInetCache:$RemoveInetCache -StartServices:$StartServices
        }
    }
    $SummaryReport = "Summary of Windows Update Components Reset:"
    $SummaryReport += "`nServices Stopped: $($Summary.ServicesStopped)"
    $SummaryReport += "`nSoftwareDistribution Folder Removed: $($Summary.SoftwareDistributionRemoved)"
    $SummaryReport += "`nInternet Cache Removed: $($Summary.InetCacheRemoved)"
    $SummaryReport += "`nServices Started: $($Summary.ServicesStarted)"
    if ($Summary.Errors.Count -gt 0) {
        $SummaryReport += "`nErrors encountered:`n" + ($Summary.Errors -join "`n")
    }
    if ($Summary.ActionsSkipped.Count -gt 0) {
        $SummaryReport += "`nActions skipped:`n" + ($Summary.ActionsSkipped -join "`n")
    }
    if ($Summary.RemovedFiles.Count -gt 0) {
        $SummaryReport += "`nFiles removed:`n" + ($Summary.RemovedFiles -join "`n")
    }
    Write-Host $SummaryReport -ForegroundColor Green
}
