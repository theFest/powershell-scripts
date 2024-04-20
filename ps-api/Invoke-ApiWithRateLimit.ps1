Function Invoke-ApiWithRateLimit {
    <#
    .SYNOPSIS
    Invokes an API with rate limiting to control the number of requests made per minute.

    .DESCRIPTION
    This function invokes an API endpoint while limiting the number of requests made per minute to prevent exceeding rate limits imposed by the API provider.

    .PARAMETER Url
    Specifies the URL of the API endpoint to be invoked.
    .PARAMETER MaxRequestsPerMinute
    Maximum number of requests allowed to be made per minute, default is 60.

    .EXAMPLE
    Invoke-ApiWithRateLimit -Url "https://jsonplaceholder.typicode.com/posts" -MaxRequestsPerMinute 5

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Url,

        [Parameter(Mandatory = $false)]
        [int]$MaxRequestsPerMinute = 60
    )
    $Pipeline = [System.Management.Automation.PowerShell]::Create().AddCommand('Invoke-RestMethod').AddParameter('Uri', $Url).AddParameter('Method', 'Get')
    $RequestsSent = 0
    $DelayMilliseconds = [math]::Ceiling(60000 / $MaxRequestsPerMinute)
    while ($RequestsSent -lt $MaxRequestsPerMinute) {
        $Pipeline.Invoke() | Out-Null
        Start-Sleep -Milliseconds $DelayMilliseconds
        $RequestsSent++
    }
    $Results = @()
    $Pipeline.Invoke() | ForEach-Object {
        $Results += $_
    }
    return $Results
}
