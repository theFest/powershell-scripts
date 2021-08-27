Function DeleteService {
    <#
    .SYNOPSIS
    Windows service removal script.
    
    .DESCRIPTION
    With this funtion you can delete Windows services.
    
    .PARAMETER ServiceName
    Mandator - declare name of the service you want to delete.
    
    .EXAMPLE
    DeleteService -ServiceName spooler
    
    .NOTES
    v1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServiceName
    )
    $Service = Get-WmiObject -Class Win32_Service -Filter "Name='$ServiceName'"
    $Service.StopService()
    Start-Sleep -Seconds 1
    $Service.Delete()
    $Service.Dispose()
}