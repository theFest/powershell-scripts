Function Get-FileS3 {
    <#
    .SYNOPSIS
    This function downloads file from Internet.
    
    .DESCRIPTION
    This function downloads file from Internet. It can be S3 bucket or any other source.
    
    .PARAMETER Key
    NotMandatory - credentials to authentificate against some source to be able to download.
    .PARAMETER FileUrl
    Mandatory - URL to the file on S3 bucket or source from you want to download.
    .PARAMETER DestinationPath
    NotMandatory - path to location where you want the file to be saved.

    .NOTES
    If absent, content will be downloaded in "$env:TEMP"
    Local and remote sources will be compared if same filename is present on disk.
    Finally it will return time taken in for download in a format of HH/MM/SS
    *for reusability purposes, remove following: WriteLog(declare_at_the_end)

    .EXAMPLE
    Get-FileS3 -Key $Key -FileUrl $your_url -DestinationPath $your_data_path

    .NOTES
    v0.1.2
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)]
        [string]$Key,

        [Parameter(Mandatory = $true)]
        [string]$FileUrl,

        [Parameter(Mandatory = $false)]
        [string]$DestinationPath
    )
    $StartTime = Get-Date
    if (!$DestinationPath) {
        $DestinationPath = $env:TEMP
    }
    $SecurePassword = ConvertTo-SecureString $Key -AsPlainText -Force
    [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls, ssl3"
    $FileName = [System.IO.Path]::GetFileName($FileUrl)
    $DownloadFilePath = [System.IO.Path]::Combine($DestinationPath, $FileName)
    $LocalPath = (Get-Item $DownloadFilePath -ErrorAction SilentlyContinue).Length
    $RemotePath = (Invoke-WebRequest $FileUrl -UserAgent $SecurePassword -UseBasicParsing -Method Head -ErrorAction SilentlyContinue).Headers.'Content-Length'
    if ([System.IO.File]::Exists($DownloadFilePath) -and $LocalPath -eq $RemotePath) {
        Write-Output -InputObject ('File already exists. Local and remote files match, exiting.')
    }
    else {
        Write-Output -InputObject ('File missing or local and remote files do not match, downloading...')
        Remove-Item -Path $DownloadFilePath -ErrorAction SilentlyContinue
        $DlClient = New-Object System.Net.WebClient;
        $DlClient.Headers.Add("User-Agent", "$SecurePassword");   
        $DlClient.DownloadFile($FileUrl, $DownloadFilePath);
        $DlClient.Dispose()
    }
    return "Time taken to download; $((Get-Date).Subtract($StartTime).Duration() -replace ".{8}$")"
}