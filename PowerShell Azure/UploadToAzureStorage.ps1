Class AzureStorageUploader {
    [string]$StorageAccountName
    [string]$StorageAccountKey
    AzureStorageUploader(
        [string]$StorageAccountName,
        [string]$StorageAccountKey) {
        $this.StorageAccountName = $StorageAccountName
        $this.StorageAccountKey = $StorageAccountKey
    }
    [void] Upload(
        [string]$LocalFilePath,
        [string]$ContainerName,
        [string]$BlobName,
        [switch]$Overwrite) {
        $Context = New-AzStorageContext `
            -StorageAccountName $this.StorageAccountName `
            -StorageAccountKey $this.StorageAccountKey
        if ($Overwrite) {
            Set-AzStorageBlobContent -File $LocalFilePath `
                -Container $ContainerName `
                -Blob $BlobName `
                -Context $Context `
                -Force `
                -Verbose
        }
        else {
            Set-AzStorageBlobContent -File $LocalFilePath `
                -Container $ContainerName `
                -Blob $BlobName `
                -Context $Context `
                -Force `
                -Verbose
        }
    }
}
Function UploadToAzureStorage {
    <#
    .SYNOPSIS
    Upload content to Azure Storage.
    
    .DESCRIPTION
    This function is used to upload file to Azure Storage, either to container or blob.
    
    .PARAMETER LocalFilePath
    Mandatory - path of the local file that needs to be uploaded to Azure storage.
    .PARAMETER StorageAccountName
    Mandatory - specify the name of the Azure storage account.
    .PARAMETER StorageAccountKey
    Mandatory - specify the key of the Azure storage account.
    .PARAMETER ContainerName
    Mandatory - specify name of the container where the file will be uploaded.
    .PARAMETER BlobName
    Mandatory - specify name of the blob that will be created in the container.
    .PARAMETER Overwrite
    Mandatory - if runbook already exists, it will be overwritten with this switch..
    
    .EXAMPLE
    UploadToAzureStorage -LocalFilePath "$env:TEMP\your_file.csv" -StorageAccountName "" -StorageAccountKey "" -ContainerName "" -BlobName "" -Overwrite -Verbose
    UploadToAzureStorage -LocalFilePath "$env:TEMP\your_file.csv" -StorageAccountName "" -StorageAccountKey "" -ContainerName "" -BlobName "" -Overwrite -Verbose
    
    .NOTES
    v1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$LocalFilePath,

        [Parameter(Mandatory = $true)]
        [string]$StorageAccountName,

        [Parameter(Mandatory = $true)]
        [string]$StorageAccountKey,

        [Parameter(Mandatory = $true)]
        [string]$ContainerName,

        [Parameter(Mandatory = $false)]
        [string]$BlobName,

        [Parameter()]
        [switch]$Overwrite
    )
    BEGIN {
        Write-Verbose -Message "Starting, prechecks in progress..."
        if (!(Get-Package -Name "Az" -ErrorAction SilentlyContinue)) {
            [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls, ssl3"
            $Latest = (Invoke-WebRequest -Uri https://github.com/Azure/azure-powershell/releases -UseBasicParsing).Links `
            | Where-Object -Property { $_.href -match 'Az-Cmdlets-\d+\.\d+\.\d+\.\d+-x64\.\d+\.msi' } `
            | Sort-Object -Property href -Descending `
            | Select-Object -First 1
            $AzPSurl = $Latest.href
            $File = "$env:TEMP\$(Split-Path $AzPSurl -Leaf)"
            Invoke-WebRequest -Uri $AzPSurl -OutFile $File -Verbose
            $AzInstallerArgs = @{
                FilePath     = 'msiexec.exe'
                ArgumentList = @(
                    "/i $File",
                    "/qr",
                    "/l* $env:TEMP\Az-Cmdlets.log"
                )
                Wait         = $true
            }
            Start-Process @AzInstallerArgs -NoNewWindow
        }
        if (!(Connect-AzAccount)) {
            Write-Output "Not logged in to Azure, logging in..."
            Connect-AzAccount -Verbose
        }
    }
    PROCESS {
        $Uploader = [AzureStorageUploader]::new($StorageAccountName, $StorageAccountKey)
        $Uploader.Upload($LocalFilePath, $ContainerName, $BlobName, $Overwrite)
    }
    END {
        Write-Verbose -Message "Finished, closing connection..."
        Disconnect-AzAccount -Verbose
    }
}