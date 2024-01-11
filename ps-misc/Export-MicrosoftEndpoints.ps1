Function Export-MicrosoftEndpoints {
    <#
    .SYNOPSIS
    Retrieves and processes Microsoft Endpoints.

    .DESCRIPTION
    This function retrieves Microsoft Endpoints from a specific URL, processes the data, and provides various details related to service areas, URLs, IP addresses, ports, notes, express routes, categories, and requirements.

    .PARAMETER CSVPath
    Specifies the path to export the retrieved Microsoft Endpoints data in CSV format.

    .EXAMPLE
    Export-MicrosoftEndpoints

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ParameterSetName = "CSV")]
        [string]$CSVPath
    )
    BEGIN {
        $SiteUrl = 'https://learn.microsoft.com/en-us/microsoft-365/enterprise/urls-and-ip-address-ranges?view=o365-worldwide'
        $JsonLink = ''
        try {
            $site = Invoke-WebRequest -Uri $SiteUrl -UseBasicParsing -ErrorAction Stop -Verbose
            $jsonLink = ($site.Links | Where-Object OuterHTML -match 'JSON formatted').href
        }
        catch {
            Write-Error -Message "Error accessing the website: $SiteUrl"
            return
        }
        try {
            $Endpoints = Invoke-WebRequest -Uri $jsonLink -ErrorAction Stop | ConvertFrom-Json
            Write-Host "Downloading worldwide Microsoft Endpoints" -ForegroundColor Green
        }
        catch {
            Write-Error -Message "Error downloading worldwide Microsoft Endpoints from $($jsonLink)"
            return
        }
        $total = @()
    }
    PROCESS {
        Write-Host "Processing items..." -ForegroundColor Green
        foreach ($Endpoint in $Endpoints) {
            $IPaddresses = if (-not $Endpoint.ips) { 'Not available' } else { $Endpoint.ips -split ' ' -join ', ' }
            $TCPPorts = if (-not $Endpoint.tcpPorts) { 'Not available' } else { $Endpoint.TCPPorts -split ',' -join ', ' }
            $UDPPorts = if (-not $Endpoint.udpPorts) { 'Not available' } else { $Endpoint.udpPorts -split ',' -join ', ' }
            $Notes = if (-not $Endpoint.notes) { 'Not available' } else { $Endpoint.Notes }
            $URLlist = if (-not $Endpoint.urls) { 'Not available' } else { $Endpoint.urls -join ', ' }
            $Total += [PSCustomObject]@{
                serviceArea            = $Endpoint.serviceArea
                serviceAreaDisplayName = $Endpoint.serviceAreaDisplayName
                urls                   = $URLlist
                ips                    = $IPaddresses
                tcpPorts               = $TCPPorts
                udpPorts               = $UDPPorts
                notes                  = $Notes
                expressRoute           = $Endpoint.expressRoute
                category               = $Endpoint.Category
                required               = $Endpoint.required
            }
        }
    }
    END {
        if ($CSVPath) {
            try {
                $Total | Sort-Object serviceAreaDisplayName | Export-Csv -Path $CSVPath -Encoding UTF8 -Delimiter ';' -NoTypeInformation -ErrorAction Stop
                Write-Host ("Saved results to {0}`nDone!" -f $CSVPath) -ForegroundColor Green
            }
            catch {
                Write-Warning -Message ("Could not save results to {0}" -f $CSVPath)
            }
        }
        else {
            Write-Host "Exporting results to Out-GridView`nDone!" -ForegroundColor Green
            $Total | Sort-Object serviceAreaDisplayName | Out-GridView -Title 'Microsoft Endpoints Worldwide'
        }
    }
}
