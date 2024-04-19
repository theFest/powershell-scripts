Function Invoke-ApiWithHMACAuth {
    <#
    .SYNOPSIS
    This function invokes a REST API with HMAC authentication.

    .DESCRIPTION
    This function sends a GET request to a specified URL with HMAC authentication using the provided API key and API secret.

    .PARAMETER Url
    Specifies the URL of the REST API.
    .PARAMETER ApiKey
    API key required for authentication.
    .PARAMETER ApiSecret
    API secret required for authentication.

    .EXAMPLE
    Invoke-ApiWithHMACAuth -Url "https://example.com/api" -ApiKey "your-api-key" -ApiSecret "your-api-secret"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Url,

        [Parameter(Mandatory = $true)]
        [string]$ApiKey,

        [Parameter(Mandatory = $true)]
        [string]$ApiSecret
    )
    $Timestamp = [math]::floor((Get-Date).ToUniversalTime().Subtract((Get-Date "1970-01-01T00:00:00Z")).TotalSeconds)
    $Signature = [System.Convert]::ToBase64String([Security.Cryptography.HMACSHA256]::new([Text.Encoding]::UTF8.GetBytes($ApiSecret)).ComputeHash([Text.Encoding]::UTF8.GetBytes("$Timestamp")))
    $Headers = @{
        'Api-Key'       = $ApiKey
        'Api-Timestamp' = $Timestamp
        'Api-Signature' = $Signature
    }
    $Response = Invoke-RestMethod -Uri $Url -Method Get -Headers $Headers
    return $Response
}
