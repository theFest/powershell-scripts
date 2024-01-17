#Requires -Version 3.0
Function Show-UserSID {
    <#
    .SYNOPSIS
    Gets the Security Identifier (SID) of one or more user accounts.

    .DESCRIPTION
    This function retrieves the Security Identifier (SID) for specified user accounts, providing flexibility in output format, domain filtering, SID verification, and logging options.

    .PARAMETER UserName
    Specifies the user names for which to retrieve the SID. You can provide a single username or an array of usernames.
    .PARAMETER OutputFormat
    Specifies the output format for displaying the SID information, values are "Table" (default), "List", "JSON", "CSV", "HTML", "XML".
    .PARAMETER OutputPath
    Specifies the path where the file will be created. If provided, output will be saved to a file with the appropriate extension.
    .PARAMETER Domain
    Specifies the domain(s) to filter user accounts. If provided, only user accounts from the specified domain(s) will be processed.
    .PARAMETER SIDCheck
    Specifies a SID to check if it belongs to the specified user(s). If provided, only users with a matching SID will be processed.
    .PARAMETER IncludeFullName
    Includes the user's full name in output. If specified, the output will include the full name; otherwise, it will display "n/a".

    .EXAMPLE
    "user0" | Show-UserSID
    Show-UserSID -UserName "user1", "user2" -OutputFormat JSON -Domain "domain" -IncludeFullName
    Show-UserSID -UserName "user1", "user2" -OutputFormat CSV -SIDCheck "S-1-5-21-123456789-1234567890-1234567890-1001" -OutputPath "$env:USERPROFILE\Desktop\uSID.csv"

    .NOTES
    v0.3.2
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, HelpMessage = "Specify the user names")]
        [ValidateNotNullOrEmpty()]
        [Alias("u")]
        [string[]]$UserName,

        [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Specify the output format")]
        [ValidateSet("Table", "List", "JSON", "CSV", "HTML", "XML")]
        [Alias("o")]
        [string]$OutputFormat = "Table",

        [Parameter(Mandatory = $false, HelpMessage = "Specify a path where the file will be created")]
        [Alias("l")]
        [string]$OutputPath,

        [Parameter(Mandatory = $false, Position = 2, HelpMessage = "Specify the domain(s) to filter users")]
        [Alias("d")]
        [string[]]$Domain,

        [Parameter(Mandatory = $false, HelpMessage = "Check if SID belongs to the declared user(s)")]
        [Alias("s")]
        [string]$SIDCheck,

        [Parameter(Mandatory = $false, HelpMessage = "Include user's full name in output")]
        [Alias("if")]
        [switch]$IncludeFullName
    )
    BEGIN {
        if ($OutputPath -and -not $OutputFormat) {
            Write-Error "If OutputPath is specified, OutputFormat must also be specified."
            return
        }
        if ($OutputFormat -and $OutputFormat -notin ("Table", "List", "JSON", "CSV", "HTML", "XML")) {
            Write-Error "Invalid OutputFormat. Please specify a valid format: Table, List, JSON, CSV, HTML, XML."
            return
        }
    }
    PROCESS {
        foreach ($User in $UserName) {
            try {
                if ($Domain -and $User -notmatch "@($Domain -join '|')") {
                    Write-Warning -Message "Skipping user '$User' as it does not belong to the specified domain(s) '$($Domain -join ', ')'"
                    continue
                }
                $NTAccount = New-Object System.Security.Principal.NTAccount($User)
                $UserSID = $NTAccount.Translate([System.Security.Principal.SecurityIdentifier]).Value
                $FullName = if ($IncludeFullName) {
                    $NTAccount.Translate([System.Security.Principal.NTAccount]).Value
                }
                if ($SIDCheck -and $UserSID -ne $SIDCheck) {
                    Write-Warning -Message "Skipping user '$User' as it does not match the specified SID '$SIDCheck'"
                    continue
                }
                $Result = [PSCustomObject]@{
                    UserName = $User
                    SID      = $UserSID
                    FullName = if ($FullName) { $FullName } else { "n/a" }
                }
                $OutputFileExtension = @{
                    "List"  = '';
                    "JSON"  = '.json';
                    "CSV"   = '.csv';
                    "HTML"  = '.html';
                    "XML"   = '.xml';
                    default = '.txt';
                }[$OutputFormat]
                $OutputFile = if ($OutputPath -match '\.\w+$') {
                    $OutputPath
                }
                else {
                    Join-Path $OutputPath "$($User)_SID$OutputFileExtension"
                }
                switch ($OutputFormat) {
                    "List" { 
                        if ($OutputPath) {
                            $Result.PSObject.Properties | ForEach-Object { "$($_.Name): $($_.Value)" } | Set-Content -Path $OutputFile -Encoding UTF8
                        }
                        else {
                            $Result.PSObject.Properties | ForEach-Object { "$($_.Name): $($_.Value)" }
                        }
                    }
                    "JSON" { 
                        if ($OutputPath) {
                            $Result | ConvertTo-Json | Set-Content -Path $OutputFile -Encoding UTF8
                        }
                        else {
                            $Result | ConvertTo-Json
                        }
                    }
                    "CSV" { 
                        if ($OutputPath) {
                            $Result | Export-Csv -Path $OutputFile -NoTypeInformation -Append
                        }
                        else {
                            $Result | Export-Csv -NoTypeInformation -Append
                        }
                    }
                    "HTML" { 
                        if ($OutputPath) {
                            $Result | ConvertTo-Html | Set-Content -Path $OutputFile -Encoding UTF8
                        }
                        else {
                            $Result | ConvertTo-Html
                        }
                    }
                    "XML" { 
                        if ($OutputPath) {
                            $Result | Export-Clixml -Path $OutputFile
                        }
                        else {
                            $Result | Export-Clixml
                        }
                    }
                    default { $Result | Format-Table -AutoSize }
                }
            }
            catch {
                Write-Error -Message "Failed to get SID for user '$User'! $_"
            }
            finally {
                Write-Verbose -Message "SID information: $Result"
            }
        }
    }
    END {
        if ($OutputPath) {
            Write-Host "SID information exported to $OutputPath" -ForegroundColor DarkCyan
        }
        Write-Output -InputObject $Result
    }
}
