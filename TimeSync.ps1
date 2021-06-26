Function TimeSync {
    <#
    .SYNOPSIS
    This function is syncing time.
    
    .DESCRIPTION
    This function starts Windows Time service, sets it to auto and syncs time.
    
    .EXAMPLE
    TimeSync
    #>
    $Time = Get-Service -Name W32Time
    $Time | Set-Service -StartupType Automatic -PassThru | Start-Service
    Start-Process W32tm -ArgumentList " /resync /force" -Wait -WindowStyle Hidden
    Write-Host "Time sync finished."
}