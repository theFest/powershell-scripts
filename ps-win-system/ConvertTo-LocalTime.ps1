function ConvertTo-LocalTime {
    <#
    .SYNOPSIS
    Converts a given date and time from a specified time zone to the local time zone.

    .DESCRIPTION
    This function takes a date and time string along with a time zone identifier and converts the given time to the local system time zone. It ensures the provided time format is valid and verifies the time zone before performing the conversion.

    .EXAMPLE
    ConvertTo-LocalTime -Time "12/30/20 10:00AM" -TimeZone UTC -Verbose

    .NOTES
    v0.2.2
    #>
    [CmdletBinding()]
    [Alias("Convert-TimeZone")]
    [OutputType([System.DateTime])]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Date and time in 'MM/dd/yy hh:mmtt' format from the other time zone")]
        [ValidateNotNullorEmpty()]
        [Alias("t")]
        [string]$Time,

        [Parameter(Mandatory = $true, HelpMessage = "Time zone from which to convert the date and time")]
        [Alias("z")]
        [ValidateSet(
            "UTC", 
            "Eastern Standard Time", 
            "Pacific Standard Time", 
            "Central Standard Time", 
            "Mountain Standard Time",
            "Central European Standard Time",
            "India Standard Time",
            "Australian Eastern Standard Time",
            "Japan Standard Time",
            "China Standard Time",
            "Greenwich Mean Time",
            "Brazil Standard Time",
            "Singapore Standard Time",
            "New Zealand Standard Time",
            "Alaskan Standard Time",
            "Hawaiian Standard Time",
            "Atlantic Standard Time",
            "South Africa Standard Time",
            "Eastern European Standard Time",
            "Arabian Standard Time",
            "Central Asia Standard Time",
            "Mexico Standard Time",
            "Venezuela Standard Time",
            "Argentina Standard Time",
            "Iran Standard Time",
            "Samoa Standard Time",
            "Indonesia Western Standard Time",
            "Afghanistan Standard Time",
            "Mauritius Standard Time",
            "Pakistan Standard Time",
            "Nepal Standard Time",
            "Sri Lanka Standard Time",
            "Bangladesh Standard Time",
            "Myanmar Standard Time",
            "Korea Standard Time",
            "Uzbekistan Standard Time",
            "Moscow Standard Time",
            "Israel Standard Time",
            "Turkey Standard Time",
            "Cape Verde Standard Time",
            "Morocco Standard Time",
            "Greenland Standard Time",
            "Eastern Africa Time",
            "Central Africa Time",
            "Azerbaijan Standard Time",
            "Georgian Standard Time",
            "Iraq Standard Time",
            "East Africa Time",
            "West Africa Time",
            "Fiji Standard Time",
            "Vanuatu Standard Time",
            "Tonga Standard Time",
            "Norfolk Island Standard Time",
            "Chatham Islands Standard Time",
            "Cook Islands Standard Time",
            "Tuvalu Time",
            "Christmas Island Standard Time",
            "Casey Time",
            "Davis Time",
            "Macquarie Island Time",
            "Palmer Time",
            "Vostok Time",
            "Indian Chagos Time",
            "French Southern and Antarctic Time",
            "Howland Island Time",
            "Line Islands Time",
            "Mawson Time",
            "Niue Time",
            "Norwegian Time",
            "Pacific Time",
            "Marquesas Time",
            "Pitcairn Standard Time",
            "Indian Maldives Time",
            "Indian Kerguelen Time",
            "West Pacific Time",
            "Australian Western Standard Time",
            "Australian Central Standard Time",
            "Lord Howe Standard Time",
            "Bougainville Standard Time",
            "East Timor Standard Time",
            "Brunei Darussalam Time",
            "Australia Central Western Standard Time",
            "Australian Central Daylight Time",
            "Australia Eastern Daylight Time",
            "Bhutan Time",
            "Nauru Time",
            "Galapagos Time",
            "French Polynesia Time",
            "Tokelau Time",
            "Niue Time",
            "Palau Time",
            "Papua New Guinea Time",
            "West Timor Time",
            "Pohnpei Standard Time",
            "Kosrae Standard Time",
            "Noumea Standard Time",
            "Solomon Islands Time",
            "East Timor Standard Time",
            "Wake Island Time"
        )]
        [string]$TimeZone
    )
    BEGIN {
        Write-Verbose -Message "Starting the conversion process..."
        try {
            $null = [DateTime]::ParseExact($Time, "MM/dd/yy hh:mmtt", [System.Globalization.CultureInfo]::InvariantCulture)
            Write-Verbose -Message "Time format is valid."
        }
        catch {
            Write-Error -Message "The time format is invalid. Please provide time in 'MM/dd/yy hh:mmtt' format"
            throw $_
        }
        if (-not (Get-TimeZone -Id $TimeZone -ErrorAction SilentlyContinue)) {
            Write-Error -Message "The specified time zone is not recognized: $TimeZone"
            throw "Invalid TimeZone: $TimeZone"
        }
        Write-Host "Initialized with Time: $Time and TimeZone: $TimeZone"
    }
    PROCESS {
        try {
            $ParsedDateTime = [DateTime]::ParseExact($Time, "MM/dd/yy hh:mmtt", [System.Globalization.CultureInfo]::InvariantCulture)
            $TZone = Get-TimeZone -Id $TimeZone -ErrorAction Stop
            $DateTime = "{0:f}" -f $ParsedDateTime
            Write-Verbose -Message "Converting $DateTime [$($TZone.Id) $($TZone.BaseUtcOffset) UTC] to local time"
            $ConvertedDateTime = $ParsedDateTime.AddHours( - ($TZone.BaseUtcOffset.TotalHours)).ToLocalTime()
            Write-Output -InputObject $ConvertedDateTime
        }
        catch {
            Write-Error -Message "An error occurred: $_"
        }
    }
    END {
        Write-Host "Conversion from $Time in $TimeZone has been completed successfully"
    }
}
