Function Get-DnsCacheReport {
    <#
    .SYNOPSIS
    Gathers DNS Cache information over a specified duration and displays the results in an Out-GridView.

    .DESCRIPTION
    This function retrieves DNS Cache information over a specified duration, showing progress and displaying the results in an Out-GridView. Optionally, it can save the results to a CSV file.

    .PARAMETER Minutes
    Duration, in minutes, for which the DNS Cache information should be gathered.
    .PARAMETER OutputPath
    Specifies the path to save the results as a CSV file.

    .EXAMPLE
    Get-DnsCacheReport -Minutes 5 -OutputPath "$env:USERPROFILE\Desktop\dns_cache.csv"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Minutes,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    $ValidateCSVPath = {
        if (-not $OutputPath) {
            return $false
        }
        if (Test-Path -Path $OutputPath -IsValid) {
            Write-Host ("Path {0} is valid, continuing..." -f $OutputPath) -ForegroundColor Green
            return $true
        }
        else {
            Write-Warning -Message ("Path {0} is not valid, please check path or permissions. Aborting..." -f $OutputPath)
            return $false
        }
    }
    $ShowProgress = {
        param (
            [int]$PercentComplete,
            [TimeSpan]$RemainingTime
        )
        $Spinner = @('|', '/', '-', '\')
        $SpinnerPos = $PercentComplete % 4
        Write-Host (" {0} " -f $Spinner[$SpinnerPos]) -ForegroundColor Green -NoNewline
        Write-Host (" Gathering DNS Cache information, {0}D {1:d2}h {2:d2}m {3:d2}s remaining..." -f $RemainingTime.Days, $RemainingTime.Hours, $RemainingTime.Minutes, $RemainingTime.Seconds) -ForegroundColor Green
    }
    $FormatDnsCacheEntry = {
        param ($Item)
        $Status = switch ($Item.Status) {
            0 { "Success" }
            9003 { "NotExist" }
            9501 { "NoRecords" }
            9701 { "NoRecords" }
        }
        $Type = switch ($Item.Type) {
            1 { "A" }
            2 { "NS" }
            5 { "CNAME" }
            6 { "SOA" }
            12 { "PTR" } 
            15 { "MX" }
            28 { "AAAA" }
            33 { "SRV" }
        }
        $Section = switch ($Item.Section) {
            1 { "Answer" }
            2 { "Authority" }
            3 { "Additional" }
        }
        [PSCustomObject]@{
            Entry      = $Item.Entry
            RecordType = $Type
            Status     = $Status
            Section    = $Section
            Target     = $Item.Data            
        }
    }
    if (-not (&$ValidateCSVPath)) {
        return
    }
    $Time = New-TimeSpan -Minutes $Minutes
    $OrigPos = $Host.UI.RawUI.CursorPosition
    $TickLength = 1
    $Total = @()
    $Date = (Get-Date) + $Time
    $RemainingTime = $Time
    while ($RemainingTime.TotalSeconds -gt 0) {
        $PercentComplete = 100 * (1 - ($RemainingTime.TotalSeconds / $Time.TotalSeconds))
        &$ShowProgress -PercentComplete $PercentComplete -RemainingTime $RemainingTime
        $Host.UI.RawUI.CursorPosition = $OrigPos
        Start-Sleep -Seconds $TickLength
        $DnsCache = Get-DnsClientCache
        $Total += $DnsCache | ForEach-Object { &$FormatDnsCacheEntry -item $_ }
        $RemainingTime = ($Date - (Get-Date))
    }
    $Host.UI.RawUI.CursorPosition = $OrigPos
    Write-Host (" * ") -ForegroundColor Green -NoNewline
    Write-Host (" Finished gathering DNS Cache information, displaying results in an Out-GridView now...") -ForegroundColor Green
    if ($OutputPath) {
        Write-Host ("Results are also saved as {0}" -f $OutputPath) -ForegroundColor Green
        $Total | Select-Object Entry, RecordType, Status, Section, Target -Unique | Sort-Object Entry | Export-Csv -Path $OutputPath -Encoding UTF8 -Delimiter ';' -NoTypeInformation -Force
    }
    $Total | Select-Object Entry, RecordType, Status, Section, Target -Unique | Sort-Object Entry | Out-GridView  
}
