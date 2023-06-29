Function BasicAPIer {
    <#
    .SYNOPSIS
    Invokes a REST API using the specified method, URL, API key, and request body.

    .DESCRIPTION
    This function sends an HTTP request to a REST API endpoint using the provided method, URL, API key, and request body. It supports the following methods: GET, POST, PUT, and DELETE.

    .PARAMETER Method
    Manadatory - specifies the HTTP method to be used in the API request. Only the methods "GET", "POST", "PUT", and "DELETE" are allowed.

    .PARAMETER Url
    Manadatory - URL of the API endpoint to be called.

    .PARAMETER ApiKey
    Manadatory - API key to be included in the request headers.

    .PARAMETER Body
    NotManadatory - the request body as an object, the object will be converted to JSON before sending the request.

    .EXAMPLE
    InvokeAPI -Method "GET" -Url "https://api.example.com" -ApiKey "your-api-key" -Body $Body

    .NOTES
    v0.0.1
    #>
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("GET", "POST", "PUT", "DELETE")]
        [string]$Method,
    
        [Parameter(Mandatory = $true)]
        [string]$Url,
       
        [Parameter(Mandatory = $true)]
        [string]$ApiKey,
        
        [Parameter(Mandatory = $false)]
        [object]$Body
    )
    try {
        $Headers = @{ "x-api-key" = $ApiKey; "content-type" = "application/json" }
        $Body = @{ 
            your_key0 = your_value0
            your_key1 = your_value1
            your_key2 = your_value2
        }
        Invoke-RestMethod -Uri $Url -Method $Method -Headers $Headers -Body ($Body | ConvertTo-Json)
    }
    catch {
        Write-Host "An error occurred while invoking the API: $_" -ForegroundColor Red
    }
}
