Function Invoke-RestApi {
    <#
    .SYNOPSIS
    Invoke a REST API with various HTTP methods, headers, and request body.

    .DESCRIPTION
    This function sends an HTTP request to a REST API endpoint using the specified method, URL, headers, and request body.
    It supports common HTTP methods like GET, POST, PUT, and DELETE, and allows custom headers to be included in the request.

    .PARAMETER Method
    Mandatory - specifies the HTTP method to be used in the API request. Only the methods "GET", "POST", "PUT", and "DELETE" are allowed.
    .PARAMETER Url
    Mandatory - URL of the API endpoint to be called.
    .PARAMETER Headers
    NotMandatory - custom headers to be included in the request. Pass them as a hashtable.
    .PARAMETER Body
    NotMandatory - request body as an object. The object will be converted to JSON before sending the request.

    .EXAMPLE
    Invoke-RestApi -Method "GET" -Url "https://api.example.com" -Headers @{ "x-api-key" = "your-api-key" } -Body @{ "your_key0" = "your_value0"; "your_key1" = "your_value1" }

    .NOTES
    v0.0.2
    #>
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("GET", "POST", "PUT", "DELETE")]
        [string]$Method,

        [Parameter(Mandatory = $true)]
        [string]$Url,

        [Parameter(Mandatory = $false)]
        [hashtable]$Headers,

        [Parameter(Mandatory = $false)]
        [object]$Body
    )
    try {
        Write-Verbose -Message "Default headers, including API key and JSON content type"
        $DefaultHeaders = @{
            "x-api-key"    = "your-api-key"
            "content-type" = "application/json"
        }
        Write-Verbose -Message "Merge custom headers with default headers"
        if ($Headers -ne $null) {
            $Headers = $Headers + $DefaultHeaders
        }
        else {
            $Headers = $DefaultHeaders
        }
        $RequestParams = @{
            Uri     = $Url
            Method  = $Method
            Headers = $Headers
        }
        Write-Verbose -Message "Add request body if provided"
        if ($null -ne $Body) {
            $RequestParams.Add("Body", ($Body | ConvertTo-Json))
        }
        Write-Verbose -Message "Invoke the REST API"
        Invoke-RestMethod @RequestParams
    }
    catch {
        Write-Host "An error occurred while invoking the API: $_" -ForegroundColor Red
    }
}
