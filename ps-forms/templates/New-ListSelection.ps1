Function New-ListSelection {
    <#
    .SYNOPSIS
    Allows selection and management of items from a list.

    .DESCRIPTION
    This function enables users to interactively select and manage items from a given list, including options to view, edit, delete, and add items.

    .PARAMETER ItemList
    NotMandatory - list of items to display for selection.
    .PARAMETER IntroductionMessage
    NotMandatory - message displayed before presenting the list of items.
    .PARAMETER AdditionalActionPrompt
    NotMandatory - message prompting for additional actions after selecting an item.
    .PARAMETER ConfirmExit
    NotMandatory - enables confirmation before exiting the selection process.

    .EXAMPLE
    New-ListSelection -ItemList @("Apple", "Banana", "Orange") -IntroductionMessage "Select a entry" -AdditionalActionPrompt "Do you want to proceed?"

    .NOTES
    v0.1.3
    #>
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, HelpMessage = "List of items to display")]
        [string[]]$ItemList = @("Item 1", "Item 2", "Item 3", "Item 4", "Item 5"),
        
        [Parameter(HelpMessage = "Message to display before the list")]
        [string]$IntroductionMessage = "Choose an item from the list below:",
        
        [Parameter(HelpMessage = "Message to prompt for additional action")]
        [string]$AdditionalActionPrompt = "Do you want to perform any additional action? (Y/N)",
        
        [Parameter(HelpMessage = "Enable confirmation before exiting")]
        [switch]$ConfirmExit
    )
    BEGIN {
        Write-Host $IntroductionMessage
        Write-Host "--------------------------------"
        for ($i = 0; $i -lt $ItemList.Count; $i++) {
            Write-Host "$($i + 1). $($ItemList[$i])"
        }
        Write-Host "0. Exit"
    }
    PROCESS {
        $SelectedIndex = Read-Host "Enter the number of the item you want to select"
        if ($SelectedIndex -gt 0 -and $SelectedIndex -le $ItemList.Count) {
            $SelectedItem = $ItemList[$SelectedIndex - 1]
            Write-Host "You selected: $SelectedItem"
        }
        elseif ($SelectedIndex -eq 0) {
            if ($ConfirmExit -and (Read-Host "Are you sure you want to exit? (Y/N)") -ne "Y") {
                continue
            }
            Write-Host "Exiting the program..."
            return
        }
        else {
            Write-Host "Invalid selection. Please enter a number between 0 and $($ItemList.Count)"
            return
        }
        $AdditionalOption = Read-Host $AdditionalActionPrompt
        if ($AdditionalOption -eq "Y") {
            Write-Host "Performing additional action..."
            Write-Host "1. Delete the selected item"
            Write-Host "2. Edit the selected item"
            Write-Host "3. Add a new item"
            $AdditionalSelection = Read-Host "Enter the number of the additional action you want to perform"
            switch ($AdditionalSelection) {
                1 {
                    $ItemList.RemoveAt($SelectedIndex - 1)
                    Write-Host "Selected item deleted."
                }
                2 {
                    $NewItemName = Read-Host "Enter the new name for the selected item"
                    $ItemList[$SelectedIndex - 1] = $NewItemName
                    Write-Host "Selected item updated."
                }
                3 {
                    $NewItemName = Read-Host "Enter the name for the new item"
                    $ItemList += $NewItemName
                    Write-Host "New item added."
                }
                default {
                    Write-Host "Invalid additional action selection."
                }
            }
        }
    }
    END {
        $ItemCount = $ItemList.Count
        $TotalCharacters = $ItemList | Measure-Object -Property Length -Sum
        Write-Host "Total number of items in the list: $ItemCount"
        Write-Host "Total characters in all items combined: $($TotalCharacters.Sum)"
        Write-Host "Thank you for using the list manager!"
    }
}
