Function Show-MenuWithRestart {
    <#
    .SYNOPSIS
    Displays an interactive menu with restart option.

    .DESCRIPTION
    This function displays an interactive menu with a list of choices and an option to restart the computer, prompts the user to select an option and performs the corresponding action.

    .PARAMETER Title
    Specifies the title of the menu.
    .PARAMETER Choices
    Array of choices to be displayed in the menu, default options include sample options, restart computer, and exit.
    .PARAMETER Timeout
    Timeout duration for user input in seconds, default is 60 seconds.
    .PARAMETER Restart
    Enable the restart computer option, if specified, the computer will restart upon selecting the corresponding option.
    .PARAMETER RestartTime
    Countdown time in seconds before restarting the computer, default is 120 seconds.

    .EXAMPLE
    "Your Menu Title" | Show-MenuWithRestart

    .NOTES
    v0.1.2
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Title = "Interactive Menu With Restart",

        [Parameter(Mandatory = $false)]
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
    Clear-Host
    Write-Host "`n$Title`n" -ForegroundColor Yellow
    for ($i = 0; $i -lt $Choices.Length; $i++) {
        Write-Host "$($i + 1). $($Choices[$i])"
    }
    $Choice = Read-Host "`nEnter your choice (1-$($Choices.Length)): "
    if (![int]::TryParse($Choice, [ref]$null) -or $Choice -lt 1 -or $Choice -gt $Choices.Length) {
        Write-Warning "Invalid choice. Please try again."
        Start-Sleep -Seconds 2
        Show-MenuWithRestart -Title $Title -Choices $Choices -Timeout $Timeout -Restart:$Restart -RestartTime $RestartTime
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
            Write-Host "Restart Computer selected." -ForegroundColor DarkCyan
            if ($Restart) {
                Write-Warning -Message "Restarting computer in $RestartTime seconds!"
                $Length = $RestartTime / 100
                for ($i = $RestartTime; $i -gt -1; $i--) {
                    $Time = [int]($i / 60)
                    Write-Progress -Activity "Restarting in..." -Status "$Time minutes $i seconds left" `
                        -PercentComplete ($i / $Length)
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
