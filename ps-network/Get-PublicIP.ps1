Function Get-MyPublicIP {
    <#
    .SYNOPSIS
    Retrieves the public IP address using various web services.

    .DESCRIPTION
    This function fetches the public IP address using specified web services like icanhazip.com, ipinfo.io, api.ipify.org, ifconfig.me, or ip-api.com.

    .PARAMETER Protocol
    NotMandatory - protocol to use for fetching the IP address (http or https).
    .PARAMETER IPAddressURI
    NotMandatory - the URI of the service used to retrieve the IP address.
    .PARAMETER DisableKeepAlive
    NotMandatory - disables the use of persistent connections for this request.
    .PARAMETER UseBasicParsing
    NotMandatory - uses Basic Parsing mode for Invoke-WebRequest.
    .PARAMETER ShowHeaders
    NotMandatory - displays the headers received from the web request.
    .PARAMETER TimeoutSeconds
    NotMandatory - timeout duration for the web request in seconds.

    .EXAMPLE
    Get-MyPublicIP -ShowHeaders

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("http", "https")]
        [string]$Protocol = "http",

        [Parameter(Mandatory = $false)]
        [ValidateSet("icanhazip.com", "ipinfo.io", "api.ipify.org", "ifconfig.me", "ip-api.com")]
        [string]$IPAddressURI = "icanhazip.com",

        [Parameter(Mandatory = $false)]
        [switch]$DisableKeepAlive,

        [Parameter(Mandatory = $false)]
        [switch]$UseBasicParsing,

        [Parameter(Mandatory = $false)]
        [switch]$ShowHeaders,

        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = 10
    )
    BEGIN {
        $Uri = "${Protocol}://$IPAddressURI/"
        $ParamHash = @{
            Uri              = $Uri
            DisableKeepAlive = $DisableKeepAlive
            UseBasicParsing  = $UseBasicParsing
            TimeoutSec       = $TimeoutSeconds
        }
        if ($ShowHeaders) {
            $ParamHash.Add("SessionVariable", "WebRequestSession")
        }
    }
    PROCESS {
        try {
            $Request = Invoke-WebRequest @ParamHash
            if ($ShowHeaders) {
                $Request.Headers
            }
            else {
                $Request.Content.Trim()
            }
        }
        catch [System.Net.WebException] {
            Write-Warning -Message "Failed to retrieve public IP address. Error: $_"
        }
        catch {
            Write-Error -Message "An unexpected error occurred: $_"
        }
    }
    END {
        if ($PSBoundParameters.ContainsKey('ShowHeaders') -and $ShowHeaders) {
            $Session = $null
            if ($WebRequestSession) {
                $Session = Get-Variable -Name "WebRequestSession" -ValueOnly -ErrorAction SilentlyContinue
            }
            if ($Session) {
                $Session.Dispose()
            }
        }
    }
}
