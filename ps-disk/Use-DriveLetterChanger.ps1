    Use-DriveLetterChanger -StartApplication
    Use-DriveLetterChanger -StartApplication -CommandLineArgs "D: E:"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Command-line arguments for Drive Letter Changer, e.g. 'D: E:", "D: E: Force", "-Drive Label E:", "-Drive Label E: Force'")]
        [string]$CommandLineArgs,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading Drive Letter Changer")]
        [uri]$DownloadUrl = "https://www.sordum.org/files/download/drive-letter-changer/dChanger.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where Drive Letter Changer will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\DriveLetterChanger",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles,

        [Parameter(Mandatory = $false, HelpMessage = "Start the Drive Letter Changer application after extraction")]
        [switch]$StartApplication
    )
