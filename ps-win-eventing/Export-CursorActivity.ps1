function Export-CursorActivity {
    <#
    .SYNOPSIS
    Monitors and logs cursor activity at specified intervals.

    .DESCRIPTION
    This function monitors the cursor's position and logs its activity at specified intervals. Function will run for a defined total runtime, and the cursor's position will be checked and logged based on the provided idle timeout.

    .EXAMPLE
    Export-CursorActivity -IdleTimeoutUnit "Seconds" -IdleTimeoutValue 5 -TotalRunTimeInSeconds 3600 -OutputFile "C:\Temp\CursorLog.txt"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true, HelpMessage = "Unit of the idle timeout")]
        [ValidateSet("Seconds", "Minutes", "Hours")]
        [string]$IdleTimeoutUnit,

        [Parameter(Position = 1, Mandatory = $true, HelpMessage = "Specify the value for the idle timeout")]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$IdleTimeoutValue,

        [Parameter(Position = 2, Mandatory = $true, HelpMessage = "Total timeout in seconds for how long the script should run")]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$TotalRunTimeInSeconds,

        [Parameter(Position = 3, HelpMessage = "File path to save the cursor position output")]
        [string]$OutputFile
    )
    Add-Type -AssemblyName System.Windows.Forms
    switch ($IdleTimeoutUnit) {
        "Seconds" { $IdleTimeoutInSeconds = $IdleTimeoutValue }
        "Minutes" { $IdleTimeoutInSeconds = $IdleTimeoutValue * 60 }
        "Hours" { $IdleTimeoutInSeconds = $IdleTimeoutValue * 3600 }
    }
    $EndTime = (Get-Date).AddSeconds($TotalRunTimeInSeconds)
    $OriginalPosX = [System.Windows.Forms.Cursor]::Position.X
    $OriginalPosY = [System.Windows.Forms.Cursor]::Position.Y
    if ($OutputFile) {
        Write-Verbose -Message "Output will be saved to file: $OutputFile"
    }
    while ($true) {
        $CurrentPosX = [System.Windows.Forms.Cursor]::Position.X
        $CurrentPosY = [System.Windows.Forms.Cursor]::Position.Y
        if ($OutputFile) {
            $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            "$Timestamp, X: $CurrentPosX, Y: $CurrentPosY" | Out-File -FilePath $OutputFile -Append
        }
        if ($CurrentPosX -ne $OriginalPosX -or $CurrentPosY -ne $OriginalPosY) {
            Write-Verbose -Message "Target cursor comes..."
        }
        else {
            Write-Verbose -Message "Target cursor leaves..."
        }
        Start-Sleep -Seconds $IdleTimeoutInSeconds
        if ((Get-Date) -ge $EndTime) {
            Write-Host "Total runtime reached, stopping monitoring."
            break
        }
    }
}
