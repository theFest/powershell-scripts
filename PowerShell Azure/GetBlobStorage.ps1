Function GetBlobStorage {
    <#
    .SYNOPSIS
    Download blobs from Azure Storage.
    
    .DESCRIPTION
    With this function you can download single or multiple blobs, even from a file.
    
    .PARAMETER StorageAccountName
    Mandatory - name of your Azure Storage Account, used to identify it in the Azure Portal.
    .PARAMETER StorageAccountKey
    Mandatory - secret key associated with your Azure Storage Account, used to authenticate and access its data.
    .PARAMETER ContainerName
    NotMandatory - name of the container within the storage account, used to group and manage related blobs.
    .PARAMETER BlobNamesFromFile
    NotMandatory - path to a file containing a list of Blob names, used to perform actions on multiple blobs at once.
    .PARAMETER ListContainers
    NotMandatory - flag to list all containers in the storage account.
    .PARAMETER ListBlobs
    NotMandatory - flag to list all blobs in a container.
    .PARAMETER DownloadBlob
    NotMandatory - flag to download a specific blob.
    .PARAMETER DownloadAllBlobs
    NotMandatory - flag to download all blobs in a container.
    .PARAMETER DownloadBlobsFromFile
    NotMandatory - flag to download multiple blobs specified in a file.
    .PARAMETER DownloadBlobDestinationPath
    NotMandatory - path to the location where you want to download the blob(s) to.
    
    .EXAMPLE
    GetBlobStorage -StorageAccountName "your_storage_acc" -StorageAccountKey "your_storage_key" -ListContainers
    GetBlobStorage -StorageAccountName "your_storage_acc" -StorageAccountKey "your_storage_key" -ContainerName "your_container_name" -ListBlobs
    GetBlobStorage -StorageAccountName "your_storage_acc" -StorageAccountKey "your_storage_key" -ContainerName "your_container_name" -DownloadBlob "your_single_blob"
    GetBlobStorage -StorageAccountName "your_storage_acc" -StorageAccountKey "your_storage_key" -ContainerName "your_container_name" -DownloadBlobsFromFile "$env:USERPROFILE\Desktop\your_blobs_list_file.txt"
    
    .NOTES
    v1.0
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$StorageAccountName,
  
        [Parameter(Mandatory = $true)]
        [string]$StorageAccountKey,
  
        [Parameter(Mandatory = $false)]
        [string]$ContainerName,
  
        [Parameter(Mandatory = $false)]
        [string]$BlobNamesFromFile,
  
        [Parameter(Mandatory = $false)]
        [switch]$ListContainers,
  
        [Parameter(Mandatory = $false)]
        [switch]$ListBlobs,
  
        [Parameter(Mandatory = $false)]
        [string]$DownloadBlob,
  
        [Parameter(Mandatory = $false)]
        [switch]$DownloadAllBlobs,
  
        [Parameter(Mandatory = $false)]
        [string]$DownloadBlobsFromFile,
  
        [Parameter(Mandatory = $false)]
        [string]$DownloadBlobDestinationPath = "$env:USERPROFILE\Downloads"
    )
    BEGIN {
        if (!(Get-AzContext)) {
            Write-Host "You're not connected to Azure, please login interactively..." -ForegroundColor Yellow
            Connect-AzAccount -Verbose
        }
        $StartTime = Get-Date
        $StorageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
    }
    PROCESS {
        if ($ListContainers) {
            Write-Host "Listing all containers..." -ForegroundColor Cyan
            Get-AzStorageContainer -Context $StorageContext -Verbose
        }
        elseif ($ListBlobs) {
            Write-Host "Listing all blobs from container..." -ForegroundColor Cyan
            Get-AzStorageBlob -Container $ContainerName -Context $StorageContext -Verbose
        }
        elseif ($DownloadBlob -or $DownloadAllBlobs -or $DownloadBlobsFromFile) {
            if (!$ContainerName) {
                Write-Error -Message "Either DownloadBlob -or DownloadAllBlobs -or DownloadBlobsFromFile parameters are required when want to download."
                return
            }
            $BlobContents = Get-AzStorageBlob -Container $ContainerName -Context $StorageContext  
            if ($DownloadBlob) {
                Get-AzStorageBlobContent -Blob $DownloadBlob -Container $ContainerName -Destination $DownloadBlobDestinationPath -Context $StorageContext -Verbose
            }
            if ($DownloadAllBlobs) {
                foreach ($Blob in $BlobContents.Name) {
                    Get-AzStorageBlobContent -Blob $Blob -Container $ContainerName -Destination $DownloadBlobDestinationPath -Context $StorageContext -Verbose
                }
            }
            if ($DownloadBlobsFromFile) {
                $BlobNames = Get-Content -Path $DownloadBlobsFromFile
                for ($i = 0; $i -lt $BlobNames.Length; $i++) {  
                    $Blob = $BlobNames[$i]  
                    Write-Host "Downloading $Blob, please wait...."  
                    Get-AzStorageBlobContent -Blob $Blob -Container $ContainerName -Destination $DownloadBlobDestinationPath -Context $StorageContext -Verbose  
                }    
            }
        }
    }
    END {
        Clear-History -Verbose
        Clear-Variable -Name StorageAccountName, StorageAccountKey -Force -Verbose
        Write-Host "Closing connecting with Azure..." -ForegroundColor DarkYellow
        Disconnect-AzAccount -Verbose
        Write-Host "Total operation duration: $((Get-Date).Subtract($StartTime).Duration() -replace ".{8}$")" -ForegroundColor Cyan 
    }
}