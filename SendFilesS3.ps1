Function SendFileS3 {
    <#
    .SYNOPSIS
    This function sends Logs and Transcripts to S3.

    .DESCRIPTION
    In this simple example we are sending report log and powershell transcript file to S3.

    .PARAMETER Key
    Mandatory - credentials to authentificate against some source to be able to download.
    .PARAMETER ReportFilePath
    Mandatory - location of report file on disk. Report file should be used in conjunction with WriteLog function.
    .PARAMETER TranscriptFilePath
    Mandatory - location of transcript file on disk. Transcript needs to be stopped to be able to send.
    .PARAMETER ReportUrlPath
    NotMandatory - destination of where you want report file to reside. If you define another destination, define it's key also.
    .PARAMETER TranScriptUrl
    NotMandatory - destination of where you want transcript file to reside. If you define another destination, define it's key also.

    .EXAMPLE
    SendFileS3 -Key 'your_bucket_key' -ReportFilePath "$env:TEMP\Report.csv" -TranscriptFilePath "$env:TEMP\Transcript.txt" -LogUrl 'https://your_destination_path/' -TranscriptUrl 'https://your_destinationpath/'

    .NOTES
    v1
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Key,

        [Parameter(Mandatory = $false)]
        [string]$ReportFilePath,

        [Parameter(Mandatory = $true)]
        [string]$TranscriptFilePath,

        [Parameter(Mandatory = $false)]
        [string]$LogUrl,

        [Parameter(Mandatory = $false)]
        [string]$TranscriptUrl
    )
    BEGIN {
        $StartTime = Get-Date
        #$SecurePassword = ConvertTo-SecureString $Key -AsPlainText -Force
        [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls, ssl3"
    }
    PROCESS {
        $ReportFileName = [System.IO.Path]::GetFileName($ReportFilePath)
        $TranScriptFileName = [System.IO.Path]::GetFileName($TranscriptFilePath)
        $ReportUrlPath = [System.IO.Path]::Combine($ReportUrlPath, $ReportFileName)
        $TranScriptUrlPath = [System.IO.Path]::Combine($TranscriptUrl, $TranScriptFileName)
        $Headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $Headers.Add("Content-Type", "text/csv")
        $Headers.Add("x-amz-acl", "bucket-owner-full-control")
        try {
            Invoke-RestMethod $ReportUrlPath -Method Put -Headers $Headers -UserAgent $Key -InFile $ReportFilePath -Verbose
            Invoke-RestMethod $TranScriptUrlPath -Method Put -Headers $Headers -UserAgent $Key -InFile $TranscriptFilePath -Verbose
            return $true
        }
        catch {
            Write-Error -Message "S3 - Cannot send information and logs!"
            return $false
        }
    }
    END {
        Write-Output "Time taken to upload; $((Get-Date).Subtract($StartTime).Duration() -replace ".{8}$")"
    }
}