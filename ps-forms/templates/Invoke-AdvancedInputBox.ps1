Function Invoke-AdvancedInputBox {
    <#
    .SYNOPSIS
    Creates an advanced input box for user interaction.

    .DESCRIPTION
    This function creates a customizable input box for users to provide input, it supports various parameters to customize the appearance and behavior of the input box.

    .PARAMETER Title
    NotMandatory - the title of the input box, should not exceed 25 characters.
    .PARAMETER Prompt
    NotMandatory - prompt or message displayed to the user in the input box, should not exceed 50 characters.
    .PARAMETER AsSecureString
    NotMandatory - indicates whether the input should be masked to return a secure string.
    .PARAMETER OkButtonLabel
    NotMandatory - specifies the label for the OK button.
    .PARAMETER CancelButtonLabel
    NotMandatory - specifies the label for the Cancel button.
    .PARAMETER DefaultText
    NotMandatory - specifies the default text displayed in the input box.
    .PARAMETER WindowWidth
    NotMandatory - specifies the width of the input box window.
    .PARAMETER WindowHeight
    NotMandatory - specifies the height of the input box window.
    .PARAMETER Theme
    NotMandatory - theme of the input box, available options: 'Light', 'Dark'.
    .PARAMETER EnableResize
    NotMandatory - indicates whether resizing of the input box window is enabled.
    .PARAMETER ShowInTaskbar
    NotMandatory - indicates whether the input box window is displayed in the taskbar.
    .PARAMETER WindowTitle
    NotMandatory - specifies the title of the input box window.

    .EXAMPLE
    Invoke-AdvancedInputBox -Title "Password Entry" -Prompt "Enter your password" -OkButtonLabel "_Submit" -CancelButtonLabel "_Cancel" -WindowWidth 500 -WindowHeight 250 -EnableResize -WindowTitle "Password Input"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding(DefaultParameterSetName = "Plain")]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory = $false, ParameterSetName = "Secure", HelpMessage = "No more than 25 characters")]
        [Parameter(Mandatory = $false, ParameterSetName = "Plain", HelpMessage = "No more than 25 characters")]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ $_.Length -le 25 })]
        [string]$Title = "User Input",

        [Parameter(Mandatory = $false, ParameterSetName = "Secure", HelpMessage = "No more than 50 characters")]
        [Parameter(Mandatory = $false, ParameterSetName = "Plain", HelpMessage = "No more than 50 characters")]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ $_.Length -le 50 })]
        [string]$Prompt = "Please enter a value:",

        [Parameter(Mandatory = $false, ParameterSetName = "Secure", HelpMessage = "Use to mask the entry and return a secure string")]
        [switch]$AsSecureString,

        [Parameter(Mandatory = $false, HelpMessage = "Specify the OK button label")]
        [string]$OkButtonLabel = "_OK",

        [Parameter(Mandatory = $false, HelpMessage = "Specify the Cancel button label")]
        [string]$CancelButtonLabel = "_Cancel",

        [Parameter(Mandatory = $false, HelpMessage = "Specify the default text")]
        [string]$DefaultText,

        [Parameter(Mandatory = $false, HelpMessage = "Specify the window width")]
        [int]$WindowWidth = 400,

        [Parameter(Mandatory = $false, HelpMessage = "Specify the window height")]
        [int]$WindowHeight = 200,

        [Parameter(Mandatory = $false, HelpMessage = "Specify the theme (Light/Dark)")]
        [ValidateSet("Light", "Dark")]
        [string]$Theme = "Dark",

        [Parameter(Mandatory = $false, HelpMessage = "Enable window resize")]
        [switch]$EnableResize,

        [Parameter(Mandatory = $false, HelpMessage = "Show in taskbar")]
        [switch]$ShowInTaskbar,

        [Parameter(Mandatory = $false, HelpMessage = "Specify the window title")]
        [string]$WindowTitle
    )
    BEGIN {
        if ($PSEdition -eq 'Core') {
            Write-Warning -Message "This command will not run on PowerShell Core!"
            return
        }
        Add-Type -AssemblyName PresentationFramework
        $XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="$Title" Height="$WindowHeight" Width="$WindowWidth" ResizeMode="CanMinimize" ShowInTaskbar="$($ShowInTaskbar.ToString().ToLower())">
    <Grid>
        <Grid.Background>
            <SolidColorBrush Color="Transparent"/>
        </Grid.Background>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <Label Content="$Prompt" VerticalAlignment="Center" HorizontalAlignment="Center" FontSize="16"/>
        <TextBox x:Name="InputBox" Grid.Row="1" Margin="10" FontSize="14" HorizontalAlignment="Center" Width="250" Text="$DefaultText"/>
        <StackPanel Orientation="Horizontal" Grid.Row="2" HorizontalAlignment="Center">
            <Button x:Name="OkButton" Content="$OkButtonLabel" Width="100" Height="30" Margin="5"/>
            <Button x:Name="CancelButton" Content="$CancelButtonLabel" Width="100" Height="30" Margin="5"/>
        </StackPanel>
    </Grid>
</Window>
"@
        try {
            $Stream = [System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($XAML))
            $InputWindow = [Windows.Markup.XamlReader]::Load($Stream)
            if ($Theme -eq "Dark") {
                $InputWindow.Background = [System.Windows.Media.Brushes]::Black
                $InputWindow.Foreground = [System.Windows.Media.Brushes]::White
            }
            $InputWindow.FindName("OkButton").Add_Click({
                    $script:myInput = if ($AsSecureString) {
                        $InputWindow.FindName("InputBox").SecurePassword | ConvertTo-SecureString -AsPlainText -Force
                    }
                    else {
                        $InputWindow.FindName("InputBox").Text
                    }
                    $InputWindow.DialogResult = $true
                    $InputWindow.Close()
                })
            $InputWindow.FindName("CancelButton").Add_Click({
                    $InputWindow.DialogResult = $false
                    $InputWindow.Close()
                })
        }
        catch {
            Write-Error -Message "An error occurred while creating the input box: $_"
            return
        }
    }
    PROCESS {
        try {
            $Result = $InputWindow.ShowDialog()
            if ($Result -eq $true) {
                return $script:myInput
            }
            else {
                return $null
            }
        }
        catch {
            Write-Error -Message "An error occurred while processing the input box: $_"
            return $null
        }
    }
    END {
        if ($InputWindow) {
            $InputWindow.Close()
            $InputWindow.Dispose()
        }
        if ($Stream) {
            $Stream.Close()
            $Stream.Dispose()
        }
    }
}
