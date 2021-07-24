Function SendFileS3 {
    <#
    .SYNOPSIS
    This function sends data to S3.
    
    .DESCRIPTION
    This function can send data such as txt/csv to some s3 location.
    
    .PARAMETER Key
    Mandatory - credentials to authentificate against some source to be able to upload.
    .PARAMETER SendURL
    Mandatory - URL where you want to send a file.
    .PARAMETER ReportFilePath
    Mandatory - location of where the file is stored on disk.

    .EXAMPLE
    SendFileS3 -Key "your_secret" -ReportFilePath "C:\your_file_path\example.csv" -SendURL "https://path_to_s3_url/example.csv"
    
    .NOTES
    Other content types; 'image/jpeg', 'text/plain', 'create/declare yours'
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Key,

        [Parameter(Mandatory = $true)]
        [string]$SendURL,

        [Parameter(Mandatory = $true)]
        [string]$ReportFilePath
    )
    $Headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $Headers.Add("Content-Type", "text/csv")
    $Headers.Add("x-amz-acl", "bucket-owner-full-control")
    $TransferURL = "$SendURL" + "$ReportFileName"
    try {
        Invoke-RestMethod $TransferURL -Method 'PUT' -Headers $Headers -UserAgent $Key -InFile "$ReportFilePath" -Verbose
        return $true
    }
    catch {
        Write-Error -Message "Cannot send information and logs to S3!" -Verbose
        return $false
    }
}