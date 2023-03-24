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
  v1.0.2
  #>
  [CmdletBinding()]
  param (
      [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure Blob Storage account")]
      [string]$StorageAccountName,

      [Parameter(Mandatory = $true, HelpMessage = "The access key for the Azure Blob Storage account")]
      [string]$StorageAccountKey,

      [Parameter(Mandatory = $false, HelpMessage = "The name of the container to list or download blobs from")]
      [string]$ContainerName,

      [Parameter(Mandatory = $false, HelpMessage = "The path to a file containing a list of blob names to download")]
      [string]$BlobNamesFromFile,

      [Parameter(Mandatory = $false, HelpMessage = "Lists all containers in the storage account")]
      [switch]$ListContainers,

      [Parameter(Mandatory = $false, HelpMessage = "Lists all blobs in the specified container")]
      [switch]$ListBlobs,

      [Parameter(Mandatory = $false, HelpMessage = "Downloads the specified blob to the specified destination path")]
      [string]$DownloadBlob,

      [Parameter(Mandatory = $false, HelpMessage = "Downloads all blobs in the specified container to the specified destination path")]
      [switch]$DownloadAllBlobs,

      [Parameter(Mandatory = $false, HelpMessage = "Downloads blobs specified specified in a file")]
      [string]$DownloadBlobsFromFile,

      [Parameter(Mandatory = $false, HelpMessage = "Location where to download blob's")]
      [string]$DownloadBlobDestinationPath = "$env:USERPROFILE\Downloads"
  )
  BEGIN {
      if (!(Get-InstalledModule -Name "Az")) {
          Write-Verbose -Message "Installing the Az PowerShell module..."
          try {
              Install-Module -Name "Az" -Scope CurrentUser -Verbose
          }
          catch {
              Write-Error "Failed to import 'Az' module. Error: $_"
              return
          }
      }
      Write-Warning -Message "Checking authentification context against Azure..."
      if (!(Get-AzContext -ErrorAction SilentlyContinue)) {
          try {
              Connect-AzAccount -ErrorAction Continue -Verbose
          }
          catch {
              Write-Error "Failed to authenticate user. Error: $_"
              return
          }
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
