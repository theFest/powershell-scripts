Function AdvancedWebRequest {
    <#
    .SYNOPSIS
    Simply execute string from url.
    
    .DESCRIPTION
    This function executes a script from a given URL, using memory execution. The file is downloaded and executed from memory.
    It also has the option to save the script to a file, return a specific class object, and run the script on a remote computer using specified credentials.
    
    .PARAMETER Key
    Mandatory - credentials to authenticate against the source to be able to download the script.
    .PARAMETER Url
    NotMandatory - url to fetch script as string.
    .PARAMETER Timeout
    NotMandatory - timeout value in milliseconds for the web request. Default value is 10000 (10 seconds)
    .PARAMETER UseProxy
    NotMandatory - switch to indicate if a proxy should be used for the web request.
    .PARAMETER ProxyServer
    NotMandatory - the proxy server to use for the web request.
    .PARAMETER SaveToFile
    NotMandatory - switch to indicate if the script should be saved to a file.
    .PARAMETER FilePath
    NotMandatory - the filepath to save the script to if the SaveToFile switch is used.
    .PARAMETER Class
    NotMandatory - the class of the object to return after downloading the script.
    .PARAMETER Params
    NotMandatory - the parameters to pass to the class constructor.
    .PARAMETER RemoteComputer
    NotMandatory - the computer to run the script on.
    .PARAMETER Credentials
    NotMandatory - the credentials to use for remote execution.
    .EXAMPLE
    AdvancedWebRequest -Key $Key -Url "https://your_url/your_script.ps1" | Invoke-Expression
    
    .NOTES
    v1.3
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Key,
    
        [Parameter(Mandatory = $true)]
        [string]$Url,
    
        [Parameter(Mandatory = $false)]
        [int]$Timeout = 10000, # Default timeout of 10 seconds
    
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
        [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls, ssl3"
        $DLClient = New-Object System.Net.WebClient; 
        $DLClient.Headers.Add("user-agent", "$Key");
        if ($UseProxy) {
            $DLClient.Proxy = New-Object System.Net.WebProxy -ArgumentList $ProxyServer
        }
        $DLClient.Timeout = $Timeout
        $result = $DLClient.DownloadString("$Url")
        if ($SaveToFile) {
            $result | Out-File -FilePath $FilePath -Encoding UTF8
        }
        $DLClient.Dispose()
        if ($RemoteComputer) {
            if ($Credentials) {
                Invoke-Command -ComputerName $RemoteComputer -Credential $Credentials -ScriptBlock {
                    param($result)
                    Invoke-Expression $result
                } -ArgumentList $result
            }
            else {
                Invoke-Command -ComputerName $RemoteComputer -ScriptBlock {
                    param($result)
                    Invoke-Expression $result
                } -ArgumentList $result
            }
        }
        else {
            if ($Class) {
                return New-Object -TypeName $Class -ArgumentList $Params
            }
            else {
                return $result
            }
        }
    }
    catch [Net.WebException] {
        Write-Debug -Message "Unable to execute script."
    }
}
    