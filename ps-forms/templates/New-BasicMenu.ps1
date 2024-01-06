Function New-BasicMenu {
    <#
    .SYNOPSIS
    This is a basic menu function.
    
    .DESCRIPTION
    This function displays a menu with various options and performs actions based on the selected option.
    
    .PARAMETER Title
    NotMandatory - the title of the menu.
    .PARAMETER Choices
    NotMandatory - array of available choices in the menu.
    .PARAMETER Timeout
    NotMandatory - timeout value for user input in seconds.
    
    .EXAMPLE
    New-BasicMenu -Title "Main Menu" -Choices @("Search Files", "Copy Files", "Delete Files", "Exit") -Timeout 60
    
    .NOTES
    v0.0.2
    #>
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $false)]
        [ValidateSet("Search Files", "Copy Files", "Delete Files", "View Logs", "Get Services", "Get Processes", "Download File", "Exit")]
        [string]$Title = "Menu",
  
        [Parameter(Position = 1, Mandatory = $false)]
        [string[]]$Choices = @("Search Files", "Copy Files", "Delete Files", "View Logs", "Get Services", "Get Processes", "Download File", "Exit"),

        [Parameter(Position = 2, Mandatory = $false)]
        [int]$Timeout = 60
    )
    Clear-Host
    Write-Host "`n$Title`n" -ForegroundColor Yellow
    Write-Host ("=" * ($Title.Length + 2)) -ForegroundColor Yellow
    for ($i = 0; $i -lt $Choices.Length; $i++) {
        Write-Host "$($i + 1). $($Choices[$i])"
    }
    Write-Host ("=" * ($Title.Length + 2)) -ForegroundColor Yellow
    $Choice = Read-Host "`nEnter your choice (1-$($Choices.Length)): "
    If (!$Choice.IsNumeric() -or $Choice -lt 1 -or $Choice -gt $Choices.Length) {
        Write-Warning "Invalid choice. Please try again."
        Start-Sleep -Seconds 2
        Show-Menu -Title $Title -Choices $Choices -Timeout $Timeout
        return
    }
    $SelectedOption = $Choices[$Choice - 1]
    Switch ($SelectedOption) {
        "Search Files" {
            Write-Host "Search Files option selected."
            Get-ChildItem -Path "C:\Path\To\Search" -Recurse -File
        }
        "Copy Files" {
            Write-Host "Copy Files option selected."
            Copy-Item -Path "C:\Source\Path" -Destination "C:\Destination\Path" -Force
        }
        "Delete Files" {
            Write-Host "Delete Files option selected."
            Remove-Item -Path "" -Force -Verbose
        }
        "View Logs" {
            Write-Host "View Logs option selected."
            Get-WinEvent
        }
        "Get Services" {
            Write-Host "Get Services selected."
            Get-Service -Name *
        }
        "Get Processes" {
            Write-Host "Get Processes selected."
            Get-Process -Name *
        }
        "Download File" {
            Write-Host "Download File selected."
            Invoke-WebRequest -Uri "" -OutFile ""
        }
        "Exit" {
            Write-Warning -Message "Exiting menu..."
            return
        }
    }
    New-BasicMenu -Title $Title -Choices $Choices -Timeout $Timeout
}
