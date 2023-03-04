Class AzureStorageUploader {
  [string]$StorageAccountName
  [string]$StorageAccountKey
  AzureStorageUploader(
    [string]$StorageAccountName,
    [string]$StorageAccountKey
  ) {
    $this.StorageAccountName = $StorageAccountName
    $this.StorageAccountKey = $StorageAccountKey
  }
  [void]Upload(
    [string]$LocalFilePath,
    [string]$ContainerName,
    [string]$BlobName,
    [switch]$Overwrite
  ) {
    $Context = New-AzStorageContext `
      -StorageAccountName $this.StorageAccountName `
      -StorageAccountKey $this.StorageAccountKey
    Set-AzStorageBlobContent -File $LocalFilePath `
      -Container $ContainerName `
      -Blob $BlobName `
      -Context $Context `
      -Force:$Overwrite `
      -Verbose
  }
}

Function UploadToAzureStorage {
  <#
  .SYNOPSIS
  Simple example of class usage for purpose of upload a file to Azure Blob Storage.

  .DESCRIPTION
  This function uploads a file from the local file system to Azure Blob Storage using the Azure PowerShell module.
  If the blob already exists in the container and the -Overwrite switch is not specified, the upload will fail.
  By default, the function installs the Azure PowerShell module if it is not already installed and logs in to Azure using the currently logged in user's credentials.

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
  Mandatory - if runbook already exists, it will be overwritten with this switch.

  .EXAMPLE
  UploadToAzureStorage -LocalFilePath "$env:TEMP\your_file.csv" -StorageAccountName "" -StorageAccountKey "" -ContainerName "" -BlobName "" -Overwrite -Verbose

  .NOTES
  v1.0.1
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
    $azModule = Get-InstalledModule -Name Az -ErrorAction SilentlyContinue
    if (!$azModule) {
      Write-Verbose -Message "Az module not found, installing latest version..."
      Install-Module -Name Az -Scope CurrentUser -Verbose -WhatIf
    }
    elseif ([version]$azModule.Version -lt [version]'5.0.0') {
      Write-Verbose -Message "Az module version $($azModule.Version) found, upgrading to latest version..."
      Update-Module -Name Az -Verbose -WhatIf
    }
    if (!(Get-AzContext)) {
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