#Requires -Version 5.1
Function Export-WhoisInfo {
    <#
    .SYNOPSIS
    Retrieves WHOIS information based on the provided target, allowing export in different formats.

    .DESCRIPTION
    This function retrieves WHOIS details for a given target (either IP or hostname) from selected WHOIS providers. It allows exporting this information in different formats such as HTML, CSV, or CSS.

    .PARAMETER Target
    Specifies the target for which WHOIS information will be retrieved. It can be an IP address or hostname. If not provided, it defaults to the public IP of the executing machine.
    .PARAMETER Provider
    WHOIS service provider to be used for retrieving information, defaults to 'whois.com'. Supported providers include whois.com, who.is, arin.net, ripe.net, apnic.net, afrinic.net, nic.at, and nic.br.
    .PARAMETER OutputFormat
    Format in which the WHOIS information will be exported, supported formats include HTML, CSV, and CSS. Defaults to 'CSV'.
    .PARAMETER ExportPath
    The path where the exported WHOIS information will be saved, the file extension will be automatically added based on the selected OutputFormat.

    .EXAMPLE
    Export-WhoisInfo -Target "8.8.8.8" -ExportPath "$env:USERPROFILE\Desktop\results"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 0)]
        [string]$Target = (Invoke-RestMethod -Uri "https://api.ipify.org?format=json" -ErrorAction SilentlyContinue).Ip,

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateSet("whois.com", "who.is", "arin.net", "ripe.net", "apnic.net", "afrinic.net", "nic.at", "nic.br")]
        [string]$Provider = "whois.com",

        [Parameter(Mandatory = $false, Position = 2)]
        [ValidateSet("CSV", "HTML", "CSS")]
        [string]$OutputFormat = "CSV",

        [Parameter(Mandatory = $false, Position = 3)]
        [string]$ExportPath
    )
    BEGIN {
        $StartTime = Get-Date
        Write-Verbose -Message "Script started at $StartTime"
        $SupportedProviders = @{
            "whois.com"   = "https://www.whois.com/whois/"
            "who.is"      = "https://www.who.is/whois/"
            "arin.net"    = "http://whois.arin.net/rest/ip/"
            "ripe.net"    = "https://apps.db.ripe.net/search/query.html?searchtext="
            "apnic.net"   = "http://wq.apnic.net/apnic-bin/whois.pl?searchtext="
            "afrinic.net" = "http://www.afrinic.net/cgi-bin/whois?searchtext="
            "nic.at"      = "https://whois.nic.at/whois/?query="
            "nic.br"      = "https://registro.br/2/whois?object="
        }
        if (-not (Get-Command ConvertFrom-HTML -ErrorAction SilentlyContinue)) {
            Write-Warning -Message "ConvertFrom-HTML not found. Please ensure you have PowerShell 7 or later installed!"
            return
        }
    }
    PROCESS {
        try {
            $IsIPAddress = $Target -as [System.Net.IPAddress]
            if ($IsIPAddress) {
                $IpAddressType = if ($Target -match ":") { "IPv6" } else { "IPv4" }
                $Ip = $Target
                $Hostname = [System.Net.Dns]::GetHostEntry($Ip).HostName
            }
            else {
                $IpAddressType = "Hostname"
                $Ip = [System.Net.Dns]::GetHostAddresses($Target) |
                Where-Object { $_.AddressFamily -eq "InterNetwork" } |
                Select-Object -First 1 -ExpandProperty IPAddressToString
                $Hostname = $Target
            }
            $WhoisUri = $SupportedProviders[$Provider]
            if (-not $WhoisUri) {
                throw "Unsupported WHOIS provider: $Provider"
            }
            $WhoisUrl = $WhoisUri + $Target
            Write-Host ("Getting WHOIS details for $Target from $Provider") -ForegroundColor Green
            Start-Sleep -Seconds 2
            $null = Invoke-RestMethod -Uri $WhoisUrl -Verbose
        }
        catch {
            Write-Warning -Message "Error getting WHOIS details for $Target from ${Provider}: $_"
            return
        }
    }
    END {
        try {
            $OutputData = [PSCustomObject]@{
                Time          = Get-Date
                Target        = $Target
                Provider      = $Provider
                IPAddressType = $IpAddressType
                IP            = $Ip
                Hostname      = $Hostname
            }
            switch ($OutputFormat) {
                "CSV" {
                    $FilePath = [System.IO.Path]::ChangeExtension($ExportPath, ".csv")
                    $OutputData | Export-Csv -Path $FilePath -NoTypeInformation -Verbose
                }
                "HTML" {
                    $FilePath = [System.IO.Path]::ChangeExtension($ExportPath, ".html")
                    $OutputData | ConvertTo-Html | Out-File -FilePath $FilePath -Encoding UTF8 -Verbose
                }
                "CSS" {
                    $FilePath = [System.IO.Path]::ChangeExtension($ExportPath, ".css")
                    $OutputData | ConvertTo-Csv -NoTypeInformation | ConvertTo-Css -PropertyNames Time, Target, Provider, IPAddressType, IP, Hostname | Out-File -FilePath $FilePath -Encoding UTF8 -Verbose
                }
                default {
                    Write-Warning -Message "Incorrect output format has been defined!"
                }
            }
            Write-Host "Exported WHOIS information to $FilePath" -ForegroundColor Cyan
            return $OutputData
        }
        catch {
            Write-Warning -Message "Error exporting WHOIS information to ${ExportPath}: $_"
            return
        }
        $EndTime = Get-Date
        $ExecutionTime = New-TimeSpan -Start $StartTime -End $EndTime
        Write-Verbose -Message "Total execution time: $($ExecutionTime.TotalSeconds) seconds"
    }
}
