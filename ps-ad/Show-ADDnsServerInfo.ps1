Function Show-ADDnsServerInfo {
    <#
    .SYNOPSIS
    Retrieves DNS server information for specified domains.

    .DESCRIPTION
    This function retrieves DNS server information, including DNS host names, IP addresses, DNS server addresses, DNS server search order, forwarders, boot method, scavenging interval, primary DNS zone, and DNS records count for the specified domains.

    .PARAMETER Domain
    Specifies the domain(s) for which DNS server information is to be retrieved. If not specified, the current domain is used.

    .EXAMPLE
    Show-ADDnsServerInfo

    .NOTES
    v0.0.1
    #>
    [CmdletBinding(ConfirmImpact = "None")]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]$Domain = ([DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().Name.ToString())
    )
    BEGIN {
        $DNSReport = @()
    }
    PROCESS {
        foreach ($Realm  in $Domain) {
            $AllDomainControllers = Get-ADDomainController -Filter "Site -like '*' -and Domain -eq '$Realm '" | Select-Object -ExpandProperty Name
            foreach ($SingleDomainController in $AllDomainControllers) {
                if ($SingleDomainController) {
                    $Forwarders = $null
                    $NetworkInterface = $null
                    Write-Verbose -Message "Attempting to retrieve DNS server information without using WMI..."
                    $Forwarders = try {
                        $Forwarders = Get-DnsServer -ComputerName $SingleDomainController -ErrorAction Stop
                    }
                    catch {
                        Write-Warning -Message "Failed to retrieve DNS server information on $SingleDomainController using native cmdlets, resorting to WMI"
                        $null
                    }
                    if (-not $Forwarders) {
                        Write-Verbose -Message "Attempting to retrieve DNS server information using WMI..."
                        $Forwarders = Get-WmiObject -ComputerName $SingleDomainController -Namespace root\MicrosoftDNS -Class MicrosoftDNS_Server -ErrorAction SilentlyContinue
                    }
                    Write-Verbose -Message "Retrieving network interface information..."
                    $NetworkInterface = Get-WmiObject -ComputerName $SingleDomainController -Query 'Select * From Win32_NetworkAdapterConfiguration Where IPEnabled=TRUE' -ErrorAction SilentlyContinue
                    if ($Forwarders -and $NetworkInterface) {
                        $DnsZone = $null
                        $DnsRecords = $null
                        Write-Verbose -Message "Retrieving primary DNS zone..."
                        $DnsZone = Get-DnsServerZone -ComputerName $SingleDomainController | Where-Object { $_.ZoneType -eq 'Primary' } | Select-Object -ExpandProperty ZoneName
                        Write-Verbose -Message "Retrieving DNS records for the domain..."
                        $DnsRecords = Get-DnsServerResourceRecord -ComputerName $SingleDomainController -ZoneName $Realm 
                        $DNSReport += [PSCustomObject]@{
                            'DC'                   = $SingleDomainController
                            'Domain'               = $Realm 
                            'DNSHostName'          = $NetworkInterface.DNSHostName
                            'IPAddress'            = $NetworkInterface.IPAddress
                            'DNSServerAddresses'   = $Forwarders.ServerAddresses
                            'DNSServerSearchOrder' = $NetworkInterface.DNSServerSearchOrder
                            'Forwarders'           = $Forwarders.Forwarders
                            'BootMethod'           = $Forwarders.BootMethod
                            'ScavengingInterval'   = $Forwarders.ScavengingInterval
                            'DnsZone'              = $DnsZone
                            'DnsRecordsCount'      = $DnsRecords.Count
                            'DnsRecords'           = $DnsRecords
                        }
                    }
                    else {
                        Write-Warning -Message "Failed to retrieve DNS server information on $SingleDomainController!"
                    }
                }
            }
        }
    }
    END {
        if ($DNSReport.Count -gt 0) {
            Write-Output -InputObject $DNSReport
        }
        else {
            Write-Warning -Message "No DNS server information found for the specified domain(s)"
        }
    }
}
