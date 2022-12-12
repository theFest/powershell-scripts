Function RunAsOtherUser {
    <#
    .DESCRIPTION
    RunAs other user, thus bypassing GPO path restrictions.

    .PARAMETER UserName
    Mandatory - Provide a user
    .PARAMETER Password
    Mandatory - Provide a password
    .PARAMETER Domain
    NotMandatory - Provide optional domain
    .PARAMETER Command
    NotMandatory - Specify command to be executed
    .PARAMETER Arguments
    NotMandatory - Specify execution arguments

    .Example
    RunAsOtherUser -Username Administrator -Password your_password -Domain your_domain -Command powershell

    .NOTES
    v1
    #>
    [CmdletBinding()]Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [String]$Username,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [String]$Password,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [String]$Domain,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [String]$Command,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [String]$Arguments   
    )
    PROCESS {
        $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
        $RunAsObject = New-Object System.Diagnostics.ProcessStartInfo
        $RunAsObject.UserName = $Username
        $RunAsObject.Password = $SecurePassword
        $RunAsObject.Domain = $Domain
        $RunAsObject.FileName = $Command
        $RunAsObject.Arguments = $Arguments
        $RunAsObject.CreateNoWindow = $true
        $RunAsObject.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
        $RunAsObject.UseShellExecute = $false
        [System.Diagnostics.Process]::Start($RunAsObject)
    }
}