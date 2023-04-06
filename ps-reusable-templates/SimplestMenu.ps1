Function SimplestMenu {
    <#
    .SYNOPSIS
    Simple menu with additonal features.

    .DESCRIPTION
    This fucntion serves as template for menu wiht switch statement options with restart.

    .PARAMETER Title
    NotMandatory - enter header menu title of choice.
    .PARAMETER Choices
    NotMandatory - declare you choices, which ever suits you.
    .PARAMETER Timeout
    NotMandatory - menu wil exit after certain period defined in parameter.
    .PARAMETER Restart
    NotMandatory - restart your computer in one of the switch statements.
    .PARAMETER RestartTime
    NotMandatory time after computer will actually go to restart.

    .EXAMPLE
    "your_menu_title" | SimplestMenu
    SimplestMenu -Title "your_menu" -Choices @("choice#1","choice#2") -Restart

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Title = "Simplest Template Menu",

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Choices = @(
            "SampleOption-1",
            "SampleOption-2",
            "SampleOption-3",
            "SampleOption-4",
            "SampleOption-5",
            "Restart Computer",
            "Exit"
        ),

        [Parameter(Mandatory = $false)]
        [ValidateRange(10, 300)]
        [int]$Timeout = 60,

        [Parameter(Mandatory = $false)]
        [switch]$Restart,

        [Parameter(Mandatory = $false)]
        [int]$RestartTime = 120
    )
    BEGIN {
        Clear-Host ; Write-Verbose -Message "Starting..."
    }
    PROCESS {
        Write-Host "`n$Title`n" -ForegroundColor Yellow
        for ($i = 0; $i -lt $Choices.Length; $i++) {
            Write-Host "$($i + 1). $($Choices[$i])" -ForegroundColor Cyan
        }
        Write-Verbose -Message "Reading users input..."
        $Choice = Read-Host "`nEnter your choice (1-$($Choices.Length)): "
        Write-Verbose -Message "Validating users input..."
        If (!$Choice -or $Choice -lt 1 -or $Choice -gt $Choices.Length) {
            Write-Warning -Message "Invalid choice. Please try again."
            Start-Sleep -Seconds 2
            SimplestMenu -Title $Title -Choices $Choices -Timeout $Timeout
            return
        }
        ## act on user's choice
        Switch ($Choices[$Choice - 1]) {
            "SampleOption-1" {
                Write-Host "Option 1 selected." -ForegroundColor DarkCyan
                ## your_code here
            }
            "SampleOption-2" {
                Write-Host "Option 2 selected." -ForegroundColor DarkCyan
                ## your_code here
            }
            "SampleOption-3" {
                Write-Host "Option 3 selected." -ForegroundColor DarkCyan
                ## your_code here
            }
            "SampleOption-4" {
                Write-Host "Option 4 selected." -ForegroundColor DarkCyan
                ## your_code here
            }
            "SampleOption-5" {
                Write-Host "Option 5 selected." -ForegroundColor DarkCyan
                ## your_code here
            }
            "Restart Computer" {
                ## your_code here with optional restart
                Write-Host "Option 5 selected." -ForegroundColor DarkCyan
                if ($Restart) {
                    Write-Warning -Message "Restarting computer in $RestartTime seconds!"
                    $Lenght = $RestartTime / 100
                    for ($RestartTime; $RestartTime -gt -1; $RestartTime--) {
                        $Time = [int](([string]($RestartTime / 60)).Split('.')[0])
                        Write-Progress -Activity "Restarting in..." -Status "$Time minutes $RestartTime seconds left" `
                            -PercentComplete ($RestartTime / $Lenght)
                        Start-Sleep -Seconds 1
                    }
                    Restart-Computer -Force
                }
            }
            "Exit" {
                Write-Warning -Message "Exiting menu..."
                return
            }
        }
    }
    END {
        Write-Verbose -Message "Calling the menu again..."
        SimplestMenu -Title $Title -Choices $Choices -Timeout $Timeout
    }
}
