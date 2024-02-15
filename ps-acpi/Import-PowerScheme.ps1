Function Import-PowerScheme {
    <#
    .SYNOPSIS
    Imports a power scheme from a specified file path.
    
    .DESCRIPTION
    This function imports a power scheme from the specified file path using the powercfg command.
    
    .PARAMETER InputPath
    Specifies the path to the power scheme file that needs to be imported.
    
    .EXAMPLE
    Import-PowerScheme -InputPath "$env:USERPROFILE\Desktop\PowerScheme.pow"
    
    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputPath
    )
    BEGIN {
        Write-Host "Importing Power Scheme..." -ForegroundColor Cyan
        if (-not (Test-Path -Path $InputPath)) {
            Write-Error -Message "File not found at $InputPath. Import operation canceled!"
            return
        }
    }
    PROCESS {
        try {
            $ArgumentList = @("/c", "powercfg /import ""$InputPath""")
            Start-Process -FilePath "cmd.exe" -ArgumentList $ArgumentList -Wait -PassThru
            Write-Host "Power scheme imported successfully from $InputPath."
        }
        catch {
            Write-Error -Message "Error importing power scheme: $_"
        }
    }
    END {
        Write-Host "Import-PowerScheme completed" -ForegroundColor Cyan
    }
}
