Function GetStringExecution {
    <#
    .SYNOPSIS
    This function executes string from url.
    
    .DESCRIPTION
    This function executes string from url, using memory execution. File is downloaded and executed from memory.
    
    .PARAMETER Key
    Mandatory    - credentials to authentificate against some source to be able to download.
    .PARAMETER Url
    NotMandatory - url to fetch script as string.

    .EXAMPLE
    GetStringExecution -Key $Key -Url https://your_url/your_script.ps1 | Invoke-Expression
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Key,

        [Parameter(Mandatory = $false)]
        [string]$Url
    )
    try {
        [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls, ssl3"
        $DLClient = New-Object System.Net.WebClient; 
        $DLClient.Headers.Add("user-agent", "$Key");   
        $DLClient.DownloadString("$Url")
        $DLClient.Dispose()
    }
    catch [Net.WebException] {
        Write-Debug -Message "Unable to execute script."
    }
}