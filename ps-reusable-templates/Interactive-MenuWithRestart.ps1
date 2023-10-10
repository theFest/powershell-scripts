Function Interactive-MenuWithRestart {
    <#
    .SYNOPSIS
    Interactive menu with additional features, including the option to restart the computer.

    .DESCRIPTION
    This function serves as a template for an interactive menu with a switch statement and restart functionality.

    .PARAMETER Title
    Not Mandatory - Enter the menu title of your choice.
    .PARAMETER Choices
    Not Mandatory - Declare your menu choices as an array.
    .PARAMETER Timeout
    Not Mandatory - The menu will exit after a specified timeout.
    .PARAMETER Restart
    Not Mandatory - Enable computer restart as one of the menu options.
    .PARAMETER RestartTime
    Not Mandatory - Specify the time before the computer restarts.

    .EXAMPLE
    "your_menu_title" | Interactive-MenuWithRestart
    Interactive-MenuWithRestart -Title "Your Menu" -Choices @("Choice #1", "Choice #2") -Restart

    .NOTES
    v0.0.2
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Title = "Interactive Menu With Restart",

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Choices = @(
            "Sample Option 1",
            "Sample Option 2",
            "Sample Option 3",
            "Sample Option 4",
            "Sample Option 5",
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
        Write-Verbose -Message "Reading user's input..."
        $Choice = Read-Host "`nEnter your choice (1-$($Choices.Length)): "
        Write-Verbose -Message "Validating user's input..."
        if (!$Choice -or $Choice -lt 1 -or $Choice -gt $Choices.Length) {
            Write-Warning -Message "Invalid choice. Please try again."
            Start-Sleep -Seconds 2
            Interactive-MenuWithRestart -Title $Title -Choices $Choices -Timeout $Timeout
            return
        }
        switch ($Choices[$Choice - 1]) {
            "Sample Option 1" {
                Write-Host "Option 1 selected." -ForegroundColor DarkCyan
                ## Your code here
            }
            "Sample Option 2" {
                Write-Host "Option 2 selected." -ForegroundColor DarkCyan
                ## Your code here
            }
            "Sample Option 3" {
                Write-Host "Option 3 selected." -ForegroundColor DarkCyan
                ## Your code here
            }
            "Sample Option 4" {
                Write-Host "Option 4 selected." -ForegroundColor DarkCyan
                ## Your code here
            }
            "Sample Option 5" {
                Write-Host "Option 5 selected." -ForegroundColor DarkCyan
                ## Your code here
            }
            "Restart Computer" {
                ## Your code here with optional restart
                Write-Host "Restart Computer selected." -ForegroundColor DarkCyan
                if ($Restart) {
                    Write-Warning -Message "Restarting computer in $RestartTime seconds!"
                    $Length = $RestartTime / 100
                    for ($RestartTime; $RestartTime -gt -1; $RestartTime--) {
                        $Time = [int](([string]($RestartTime / 60)).Split('.')[0])
                        Write-Progress -Activity "Restarting in..." -Status "$Time minutes $RestartTime seconds left" `
                            -PercentComplete ($RestartTime / $Length)
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
        Interactive-MenuWithRestart -Title $Title -Choices $Choices -Timeout $Timeout
    }
}
