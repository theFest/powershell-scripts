Function New-Base64Encode {
    <#
    .SYNOPSIS
    Encodes a string to Base64.
    
    .DESCRIPTION
    This function encodes a given string into its Base64 representation.

    .PARAMETER InputString
    Mandatory - specifies the string to be encoded to Base64.
    
    .EXAMPLE
    New-Base64Encode -InputString "Hello, World!"
    
    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$InputString
    )
    PROCESS {
        try {
            $Bytes = [System.Text.Encoding]::UTF8.GetBytes($InputString)
            $Base64String = [System.Convert]::ToBase64String($Bytes)
            Write-Output -InputObject $Base64String
        }
        catch {
            Write-Error -Message "Error encoding to Base64: $_"
        }
    }
}
