Function ShowListWithSelection {
    $List = @("Item 1", "Item 2", "Item 3", "Item 4", "Item 5")
    Write-Host "Choose an item from the list below:"
    Write-Host "--------------------------------"
    for ($i = 0; $i -lt $List.Count; $i++) {
        Write-Host "$($i + 1). $($list[$i])"
    }
    Write-Host "0. Exit"
    $SelectedIndex = Read-Host "Enter the number of the item you want to select"
    if ($SelectedIndex -gt 0 -and $SelectedIndex -le $list.Count) {
        $SelectedItem = $List[$SelectedIndex - 1]
        Write-Host "You selected: $SelectedItem"
        Write-Host "`nDisplaying selected item with a visual effect..."
        Write-Host "`n$SelectedItem`n" -ForegroundColor Yellow
    }
    elseif ($SelectedIndex -eq 0) {
        Write-Host "Exiting the program..."
        return
    }
    else {
        Write-Host "Invalid selection. Please enter a number between 0 and $($List.Count)"
    }
    $AdditionalOption = Read-Host "Do you want to perform any additional action? (Y/N)"
    if ($AdditionalOption -eq "Y") {
        Write-Host "Performing additional action..."
        Write-Host "1. Delete the selected item"
        Write-Host "2. Edit the selected item"
        Write-Host "3. Add a new item"
        $AdditionalSelection = Read-Host "Enter the number of the additional action you want to perform"
        switch ($AdditionalSelection) {
            1 {
                $List.RemoveAt($SelectedIndex - 1)
                Write-Host "Selected item deleted."
            }
            2 {
                $NewItemName = Read-Host "Enter the new name for the selected item"
                $List[$SelectedIndex - 1] = $NewItemName
                Write-Host "Selected item updated."
            }
            3 {
                $NewItemName = Read-Host "Enter the name for the new item"
                $List += $NewItemName
                Write-Host "New item added."
            }
            default {
                Write-Host "Invalid additional action selection."
            }
        }
    }
}
