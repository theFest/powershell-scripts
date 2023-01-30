Function RepairTaskPS1 {
    <#
    .SYNOPSIS
    Primary use is for when Task Scheduler throws an following error: "The selected task 'your_task' no longer exists. To see the current tasks, click Refresh."

    .DESCRIPTION
    Query for particular(your_task) task and it's 'LastTaskResult', check system for presence of task, then delete that task. Verify if it still exists is registry, add it from web source or s3 bucket.
    Retry counts(30) has been set to check if task is in running state, if not, wait for to finish and get back to ready state. If in final check we have a 'LastTaskResult' with '0', then task fix has been succesful. Lastly if you want, send log to desired destination.
    *example would be as follows: "'Invoke-WebRequest -Uri your_web_url/your_execution_script.ps1 -UserAgent '' -UseBasicParsing | Invoke-Expression'" --> schtasks.exe /create --> schtasks.exe /run

    .PARAMETER TaskPathName
    NotMandatory - name and path of a particular task e.g. '\your_parent_task_folder\your_task_name' 
    .PARAMETER TaskSource
    NotMandatory - web source of your .ps1 script that has a role of executing script via schedule task  
    .PARAMETER Counts
    NotMandatory - predifined retry counts for waiting a task to get back to 'Ready(0)' state
    .PARAMETER WebUrlPath
    NotMandatory - here declare your web destination where you want your log/report to be sent
    .PARAMETER WebPathKey
    NotMandatory - in conjunction with 'WebUrlPath' parameter, here enter your access key of that web destination
    .PARAMETER RemoteComputer
    NotMandatory - if sending log/report to another computer, here define Hostname and it's path e.g. "\\remote_hostname\C:\SharedFolder"
    .PARAMETER RemoteComputerUser
    NotMandatory - related to 'RemoteComputer' parameter, here enter a user that has the right permissions to send in some shared directory
    .PARAMETER RemoteComputerPass
    NotMandatory - self explanatory, related to 'RemoteComputer' and 'RemoteComputerUser' parameters, here enter a password of given user of remote computer
    .PARAMETER DataPath
    NotMandatory - in this location .ps1 execution file will be downloaded and stored 
    .PARAMETER LogFilePath
    NotMandatory - self explanatory, desired location for log to be stored, appended and eventually sent
    .PARAMETER Restart
    NotMandatory - use this switch if you plan to restart your computer after scheduled task has been fixed
    .PARAMETER RestartTime
    NotMandatory - predifined countdown time after which computer will be restarted, change it to suit your needs

    .EXAMPLE
    RepairTaskPS1 -TaskPathName "\your_task_folder\task_name" -TaskSource "https://your_source_url/your_script.ps1" -WebPathKey "your_web_source_secret"
    RepairTaskPS1 -TaskPathName "\your_task_folder\task_name" -TaskSource "https://your_source_url/your_script.ps1" -WebPathKey "your_web_source_secret" -WebUrlPath "https://your_web_source/some_path"
    RepairTaskPS1 -TaskPathName "\your_task_folder\task_name" -TaskSource "https://your_source_url/your_script.ps1" -WebPathKey "your_web_source_secret" -RemoteComputer "\\hostname\C:\Share" -RemoteComputerUser "your_user" -RemoteComputerPass "your_pass"

    .NOTES
    v1
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [string]$TaskPathName,

        [Parameter(Mandatory = $false, Position = 1)]
        [uri]$TaskSource,

        [Parameter(Mandatory = $false)]
        [int]$Counts = 24,

        [Parameter(Mandatory = $false)]
        [uri]$WebUrlPath,
        
        [Parameter(Mandatory = $false)]
        [string]$WebPathKey,
        
        [Parameter(Mandatory = $false)]
        [string]$RemoteComputer,

        [Parameter(Mandatory = $false)]
        [string]$RemoteComputerUser,

        [Parameter(Mandatory = $false)]
        [string]$RemoteComputerPass,

        [Parameter(Mandatory = $false)]
        [string]$DataPath = "$env:TEMP\FixScheduledTask",

        [Parameter(Mandatory = $false)]
        [string]$LogFilePath = "$env:USERPROFILE\FixScheduledTask_$env:COMPUTERNAME.txt",

        [Parameter(Mandatory = $false)]
        [switch]$Restart,

        [Parameter(Mandatory = $false)]
        [int]$RestartTime = '12'
    )
    $StartTime = Get-Date
    $TaskName = [System.IO.Path]::GetFileName($TaskPathName)
    $TaskPath = Split-Path -Path $TaskPathName
    $LocalPathFolder = [System.IO.Path]::GetDirectoryName($DataPath)
    $LocalPathFolderName = [System.IO.Path]::GetFileName($DataPath)
    New-Item -Path $LocalPathFolder -Name $LocalPathFolderName -ItemType Directory -Force | Out-Null
    Start-Transcript -Path $LogFilePath -Force
    Write-Output "INFO: Gathering and preparing '$TaskName' task information..."
    $FileGet = [System.IO.Path]::GetFileName($TaskSource)
    $DLFilePathGET = [System.IO.Path]::Combine($DataPath, $FileGet)
    $LengthCheckBlock = {
        $LocalPath = (Get-Item $DLFilePathGET -ErrorAction SilentlyContinue).Length
        $RemotePath = (Invoke-WebRequest -Uri $TaskSource -UserAgent $WebPathKey -UseBasicParsing -Method Head -WarningAction SilentlyContinue).Headers.'Content-Length'
        $LRCheck = [System.IO.File]::Exists($DLFilePathGET) -and $LocalPath -eq $RemotePath
        return $LRCheck
    }
    $Schedule = New-Object -ComObject Schedule.Service 
    $Schedule.Connect()
    $QT = $Schedule.GetFolder("$TaskPath").GetTasks(0)
    $QTN = $QT | Where-Object Name -eq "$TaskName"
    Write-Output "TASK=IB: Last Task Result [BEFORE] of '$TaskName': $($QTN.LastTaskResult)"
    $TaskQueryObject = [PSCustomObject]@{
        'SchTasks'     = 
        if ($QTN) { "INFO: $TaskName is present in SchTasks library" } else { "INFO: $TaskName is missing in SchTasks library" }
        'WinDirTask'   = 
        if (Test-Path -Path "$env:windir\System32\Tasks$TaskPathName") { "INFO: $TaskName is present in 'C:\Windows\System32\Tasks$TaskPath'" } else { "INFO: $TaskName is missing in 'C:\Windows\System32\Tasks$TaskPath'" }
        'RegistryTask' = 
        if (Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree$TaskPathName") { "INFO: $TaskName is present in Windows Registry" } else { "INFO: $TaskName is missing in Windows Registry" }
    }
    Write-Output -InputObject $TaskQueryObject.SchTasks, $TaskQueryObject.WinDirTask, $TaskQueryObject.RegistryTask
    if ((Get-WMIObject -Class Win32_OperatingSystem).Version -match "6.1") {
        Write-Output "INFO: Windows 7 detected, deleting $TaskName using schtasks.exe..."
        Start-Process schtasks -ArgumentList "/Delete /TN $TaskPathName /F" -NoNewWindow
    }
    else {
        $DT = $Schedule.GetFolder("$TaskPath")
        if ($DT.GetTask("$TaskName") | Out-Null) {
            Write-Output "INFO: Windows 10.* detected, deleting $TaskName via com object usage..."
            $DT.DeleteTask("$TaskName", 0)
        }
    }
    Write-Output "INFO: Checking if $TaskName task is deleted from registry..."
    try {
        if (-Not (Test-Path -Path $TaskPathName -ErrorAction Stop)) {
            Write-Output "SUCCESS: Succesfully deleted, continuing..."
        }
        else {
            throw "FAILED: Failed to find the $TaskPathName - exiting!!!"
            Stop-Transcript
            exit
        }
    }
    catch [Microsoft.PowerShell.Commands.TestPathType] {           
        $_
        Write-Error -Message "ERROR: Unknown Error, error message: $($Error[0].Exception.Message)"
    }
    Write-Output "INFO: Downloading and adding $TaskName to scheduled task library..."
    Invoke-WebRequest -Uri $TaskSource -UserAgent $WebPathKey -UseBasicParsing -OutFile $DLFilePathGET -Verbose
    $DLFilePathGET | Invoke-Expression
    if (Invoke-Command -ScriptBlock $LengthCheckBlock) {
        Write-Output "SUCCESS: Either file already exists or is downloaded. Local and remote files match, continuing..."
    }
    Write-Output "INFO: Querying $TaskName scheduled task status..."
    $DITaskState = $Schedule.GetRunningTasks(0) | Where-Object -Property Name -EQ $TaskName
    $DITaskState.Refresh()
    Start-Sleep -Seconds 2
    Write-Output "INFO: Task is still in 'Running' state, waiting it to finish and be in Ready state..."
    if ($DITaskState) {
        $Timer = [Diagnostics.Stopwatch]::StartNew()
        $Counter = 0
        do {
            Write-Output "INFO: Current state of $TaskName task: $($DITaskState.State)"
            if ((Get-WMIObject -Class Win32_OperatingSystem).Version -match "6.1") {
                $TaskStatus = schtasks /query /fo CSV | ConvertFrom-CSV
                $DIT = $TaskStatus | Where-Object { $_.TaskName -eq "$TaskPathName" }
            }
            else {
                $GTN = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
            }
            Start-Sleep -Seconds 1
            $Counter += 1
            if ($DIT.Status -eq 'Ready' -or $GTN.State -eq 'Ready') {
                Write-Output "SUCCESS: $TaskName is now in ready state($($QTN.LastTaskResult)), continuing..."
                break
            }
            else {
                Write-Error -Message "FAILED: '$TaskName' is not 'Ready' state!!!"
            }
        }
        until ($DIT.Status -eq 'Ready' -or $GTN.State -eq 'Ready' -or $Counter -ge $Counts)
        Write-Output "INFO: Waited for [$($Timer.Elapsed.TotalSeconds)] seconds for '$TaskName' task"
    }
    Write-Output "TASK=IA: Last Task Result(AFTER) of '$TaskName': $($QTN.LastTaskResult)"
    Write-Output -InputObject $TaskQueryObject.SchTasks, $TaskQueryObject.WinDirTask, $TaskQueryObject.RegistryTask
    Write-Output "INFO: Time taken to fix '$TaskName' task:[$((Get-Date).Subtract($StartTime).Duration() -replace ".{8}$")]"
    Stop-Transcript
    if ($WebUrlPath -or $RemoteComputer) {
        Start-Transcript -Path $LogFilePath -Append
        switch ($PSBoundParameters.Keys) {
            'WebUrlPath' {
                Write-Output "INFO: Preparing to send transcript log to choosen Web destination..."
                [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls, ssl3"
                $Headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
                $Headers.Add("Content-Type", "text/csv")
                $Headers.Add("x-amz-acl", "bucket-owner-full-control")
                $SendName = [System.IO.Path]::GetFileName($LogFilePath)
                $SendUrlPath = [System.IO.Path]::Combine("$WebUrlPath/$SendName")
                if (Test-NetConnection -ComputerName $WebUrlPath.Host) {
                    Write-Output "INFO: Connection test for choosen Web destination has passed..."
                    Stop-Transcript
                    try {
                        Write-Output "INFO: Sending transcript log is starting..."
                        Invoke-RestMethod $SendUrlPath -Method "PUT" -Headers $Headers -UserAgent $WebPathKey -InFile $LogFilePath -Verbose      
                    }
                    catch {
                        if ($_.ErrorDetails.Message) {
                            Write-Error -Message "Cannot send transcript log information to Web destination!"
                        }
                        else {
                            Write-Output $_
                        }
                    }
                    finally {
                        Clear-Variable -Name TaskSource, WebPathKey, WebUrlPath -Force -ErrorAction SilentlyContinue
                    }
                }
                else {
                    Write-Error -Message "ERROR: Connection test for for choosen Web destination has failed, unable to send log!"
                }
            }
            'RemoteComputer' {
                $Hostname = New-Object System.Uri($RemoteComputer)
                $RemoteHost = $Hostname.Host
                $GetLogName = [System.IO.Path]::GetFileName($LogFilePath)
                $GetHostChild = Split-Path -Path $Hostname -Leaf
                $RemoteSysDrive = (Split-Path $Hostname.AbsolutePath).Replace('/', '').Replace('\', '')
                $RemoteDestination = [System.IO.Path]::Combine("$RemoteSysDrive\$GetHostChild\$GetLogName")
                Write-Output "INFO: Sending log to remote computer: $($Hostname.Host)"
                $SecRemotePassword = ConvertTo-SecureString -AsPlainText $RemoteComputerPass -Force
                $SecuredCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $RemoteComputerUser, $SecRemotePassword
                Write-Output "INFO: Testing if WinRM is properly configured on remote computer..."
                try {
                    if (Test-WSMan -ComputerName $RemoteHost -Authentication default -Credential $SecuredCredentials) {
                        Write-Output "INFO: WinRM test has passed successfully, sending log to '$RemoteComputer'..."
                        $RemoteSession = New-PSSession -ComputerName $RemoteHost -Credential $SecuredCredentials -Verbose
                        Stop-Transcript
                        Copy-Item -Path $LogFilePath -Destination $RemoteDestination -ToSession $RemoteSession -Verbose
                        $RemoteSession | Remove-PSSession -Verbose
                    }
                    else {
                        Write-Error -Message "ERROR: WinRM is not properly configured, file copy has failed!"
                    }
                }
                catch {
                    Write-Error -Message "ERROR: Sending transcript file has failed!"
                    Stop-Transcript
                }
                finally {
                    Clear-Variable -Name RemoteComputerUser, RemoteComputerPass, SecRemotePassword, SecuredCredentials -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }
    if ($Restart) {
        Clear-History -Verbose
        Write-Warning "Restarting computer in $RestartTime seconds!"
        $Lenght = $RestartTime / 100
        for ($RestartTime; $RestartTime -gt -1; $RestartTime--) {
            $Time = [int](([string]($RestartTime / 60)).Split('.')[0])
            Write-Progress -Activity "Restarting in..." -Status "$Time minutes $RestartTime seconds left" -PercentComplete ($RestartTime / $Lenght)
            Start-Sleep -Seconds 1
        }
        Restart-Computer -Force
    }
}