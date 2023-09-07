Function Invoke-AdvancedWebRequest {
    <#
    .SYNOPSIS
    Performs an advanced web request with various options.

    .DESCRIPTION
    This function allows you to make web requests with advanced options such as specifying a user agent, using a proxy server, saving the response to a file, and executing the response content.

    .PARAMETER Key
    Mandatory - the user agent key for the web request.
    .PARAMETER Url
    Mandatory - the URL to send the web request to.
    .PARAMETER Timeout
    NotMandatory - timeout for the web request in milliseconds, default is 10000ms.
    .PARAMETER UseProxy
    NotMandatory - whether to use a proxy server for the web request.
    .PARAMETER ProxyServer
    NotMandatory - proxy server address to use if 'UseProxy' is enabled.
    .PARAMETER SaveToFile
    NotMandatory - indicates whether to save the web response to a file.
    .PARAMETER FilePath
    NotMandatory - path where the web response should be saved if 'SaveToFile' is enabled.
    .PARAMETER Class
    NotMandatory - the class to create using the web response content.
    .PARAMETER Params
    NotMandatory - an array of parameters to pass when creating an object using the 'Class' parameter.
    .PARAMETER RemoteComputer
    NotMandatory - name of a remote computer where the web request should be executed.
    .PARAMETER Credentials
    NotMandatory - credentials to use when executing the web request on a remote computer.

    .EXAMPLE
    Invoke-AdvancedWebRequest -Key "MyUserAgent" -Url "https://example.com" -Timeout 5000 -UseProxy -ProxyServer "http://proxyserver:8080" -SaveToFile -FilePath "C:\Response.html" -Class "MyClass" -Params @("param1", "param2")

    .NOTES
    v0.0.4
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Key,
    
        [Parameter(Mandatory = $true)]
        [string]$Url,
    
        [Parameter(Mandatory = $false)]
        [int]$Timeout = 10000,
    
        [Parameter(Mandatory = $false)]
        [switch]$UseProxy,
    
        [Parameter(Mandatory = $false)]
        [string]$ProxyServer,
    
        [Parameter(Mandatory = $false)]
        [switch]$SaveToFile,
    
        [Parameter(Mandatory = $false)]
        [string]$FilePath,
    
        [Parameter(Mandatory = $false)]
        [string]$Class,
    
        [Parameter(Mandatory = $false)]
        [object[]]$Params,
    
        [Parameter(Mandatory = $false)]
        [string]$RemoteComputer,
    
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]$Credentials
    )
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
        $WebClient = New-Object System.Net.WebClient
        $WebClient.Headers.Add("user-agent", "$Key")
        if ($UseProxy) {
            $WebClient.Proxy = New-Object System.Net.WebProxy -ArgumentList $ProxyServer
        }
        $WebClient.Timeout = $Timeout
        $Result = $WebClient.DownloadString("$Url")
        if ($SaveToFile) {
            $Result | Out-File -FilePath $FilePath -Encoding UTF8
        }
        $WebClient.Dispose()
        if ($RemoteComputer) {
            if ($Credentials) {
                Invoke-Command -ComputerName $RemoteComputer -Credential $Credentials -ScriptBlock {
                    param($Result)
                    Invoke-Expression $Result
                } -ArgumentList $Result
            }
            else {
                Invoke-Command -ComputerName $RemoteComputer -ScriptBlock {
                    param($Result)
                    Invoke-Expression $Result
                } -ArgumentList $Result
            }
        }
        else {
            if ($Class) {
                return New-Object -TypeName $Class -ArgumentList $Params
            }
            else {
                return $Result
            }
        }
    }
    catch [Net.WebException] {
        Write-Debug -Message "Unable to execute web request."
    }
}
