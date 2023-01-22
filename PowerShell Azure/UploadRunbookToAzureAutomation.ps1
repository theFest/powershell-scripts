Class AzureAutomation {
    [string]$AutomationAccountName
    [string]$ResourceGroupName
    AzureAutomation(
        [string]$AutomationAccountName,
        [string]$ResourceGroupName) {
        $this.AutomationAccountName = $AutomationAccountName
        $this.ResourceGroupName = $ResourceGroupName
    }
    [void] UploadRunbook(
        [string]$RunbookName,
        [string]$Path,
        [switch]$Overwrite,
        [string]$Type,
        [string]$Description,
        [string]$ImportRunbook,
        [string]$StartRunbook,
        [switch]$Publish = $false) {
        Get-AzAutomationAccount -Name $this.AutomationAccountName `
            -ResourceGroupName $this.ResourceGroupName `
            -Verbose
        $Runbook = Get-AzAutomationRunbook -Name $RunbookName `
            -AutomationAccountName $this.AutomationAccountName `
            -ResourceGroupName $this.ResourceGroupName `
            -ErrorAction SilentlyContinue `
            -Verbose
        switch ($Runbook) {
            $null {
                break
            }
            default {
                switch ($Overwrite) {
                    $true {
                        Remove-AzAutomationRunbook -Name $RunbookName `
                            -AutomationAccountName $this.AutomationAccountName `
                            -ResourceGroupName $this.ResourceGroupName `
                            -Force -Verbose
                        break
                    }
                    default {
                        throw "Runbook already exists and -Overwrite switch not specified"
                    }
                }
            }
        }
        Get-Content $Path -Raw -Force -Verbose
        $Runbook = New-AzAutomationRunbook -Name $RunbookName `
            -AutomationAccountName $this.AutomationAccountName `
            -ResourceGroupName $this.ResourceGroupName `
            -Description $this.Description `
            -Type $this.Type `
            -Verbose

        Set-AzAutomationRunbook -Name $RunbookName `
            -ResourceGroupName $this.ResourceGroupName `
            -AutomationAccountName $this.AutomationAccountName `
            -Description -Verbose
        switch ($ImportRunbook) {
            $null {            }
            default {
                Import-AzAutomationRunbook -Name $RunbookName `
                    -AutomationAccountName $this.AutomationAccountName `
                    -ResourceGroupName $this.ResourceGroupName `
                    -Description $Description `
                    -Path $ImportRunbook `
                    -Type $Type `
                    -Verbose `
                    -Force
            }
        }
        switch ($Publish) {
            $false {
                break
            }
            default {
                Publish-AzAutomationRunbook -Name $RunbookName `
                    -AutomationAccountName $this.AutomationAccountName `
                    -ResourceGroupName $this.ResourceGroupName `
                    -Verbose
            }
        }
        switch (StartRunbook) {
            try {
                Start-AzAutomationRunbook -Name $RunbookName `
                    -AutomationAccountName $this.AutomationAccountName `
                    -ResourceGroupName $this.ResourceGroupName `
                    -Confirm:$true `
                    -WhatIf:$true
                Write-Verbose "Runbook '$RunbookName' started"
            } 
            catch {
                Write-Error $_.Exception
            }
        }
    }
    [void] ExportRunbook(
        [string]$RunbookName,
        [string]$Path) {
        Export-AzAutomationRunbook -Name $RunbookName `
            -AutomationAccountName $this.AutomationAccountName `
            -ResourceGroupName $this.ResourceGroupName `
            -Path $Path -Force -Verbose
    }
    [void] ScheduleRunbook(
        [string]$RunbookName,
        [string]$ScheduleName,
        [string]$Schedule) {
        New-AzAutomationSchedule -Name $ScheduleName `
            -AutomationAccountName $this.AutomationAccountName `
            -ResourceGroupName $this.ResourceGroupName `
            -RunbookName $RunbookName `
            -Schedule $Schedule `
            -Verbose
    }
    [void] RegisterScheduledRunbook(
        [string]$RunbookName,
        [string]$ScheduleName) {
        Register-AzAutomationScheduledRunbook -Name $RunbookName `
            -AutomationAccountName $this.AutomationAccountName `
            -ResourceGroupName $this.ResourceGroupName `
            -ScheduleName $ScheduleName `
            -Verbose
    }
    [void] UnregisterScheduledRunbook(
        [string]$RunbookName,
        [string]$ScheduleName) {
        Unregister-AzAutomationScheduledRunbook -Name $RunbookName `
            -AutomationAccountName $this.AutomationAccountName `
            -ResourceGroupName $this.ResourceGroupName `
            -ScheduleName $ScheduleName `
            -Force `
            -Verbose
    }
}

Function UploadRunbookToAzureAutomation {
    <#
    .SYNOPSIS
    Create, upload and manage Azure Automation Runbook.

    .DESCRIPTION
    Class-based function with which you can create, upload and publish Runbook with it's script.

    .PARAMETER RunbookName
    Mandatory - name of the runbook being uploaded or created.
    .PARAMETER Path
    Mandatory - path of the runbook's script file that will be uploaded.
    .PARAMETER AutomationAccountName
    Mandatory - the name of the automation account that the runbook will be uploaded to.
    .PARAMETER ResourceGroupName
    Mandatory - name of the resource group that the automation account is located in.
    .PARAMETER Description
    NotMandatory - description of the runbook.
    .PARAMETER Type
    NotMandatory - type of the runbook that is being uploaded.
    .PARAMETER ImportRunbook
    NotMandatory - import runbook to your Automation account.
    .PARAMETER StartRunbook
    NotMandatory - start runbook on your Automation account.
    .PARAMETER Publish
    NotMandatory - choose if runbook should be published after uploading.
    .PARAMETER Overwrite
    NotMandatory - if runbook already exists, it will be overwritten with this switch.

    .EXAMPLE
    "your_RunBook" | UploadRunbookToAzureAutomation -Path "your_local_script_path" -AutomationAccountName "your_az_automationaccountname" -ResourceGroupName "your_resource_group" -Description "some_description" -Type PowerShell -Publish -Overwrite -Verbose
    UploadRunbookToAzureAutomation -RunbookName "your_RunBook" -Path "your_local_script_path" -AutomationAccountName "your_az_automationaccountname" -ResourceGroupName "your_resource_group" -Description "some_description" -Type PowerShell -Publish -Overwrite -Verbose

    .NOTES
    v1.3.1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$RunbookName,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Path $_ -PathType 'Leaf' })]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$AutomationAccountName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroupName,

        [Parameter(Mandatory = $false)]
        [string]$Description = "Runbook uploaded using PowerShell function",

        [Parameter(Mandatory = $false)]
        [ValidateSet("PowerShell", "GraphicalPowerShell", "PowerShellWorkflow", "GraphicalPowerShellWorkflow", "Graph", "Python2", "Python3")]
        [string]$Type = "PowerShell",

        [Parameter(Mandatory = $false)]
        [string]$ImportRunbook,

        [Parameter(Mandatory = $false)]
        [switch]$StartRunbook,

        [Parameter(Mandatory = $false)]
        [switch]$Publish = $false,

        [Parameter(Mandatory = $false)]
        [switch]$Overwrite
    )
    BEGIN {
        Write-Verbose -Message "Starting, prechecks in progress..."
        if (!(Get-Package -Name "Az" -ErrorAction SilentlyContinue)) {
            [Net.ServicePointManager]::SecurityProtocol = "tls12"
            $Latest = (Invoke-WebRequest -Uri https://github.com/Azure/azure-powershell/releases -UseBasicParsing).Links `
            | Where-Object -Property { $_.href -match 'Az-Cmdlets-\d+\.\d+\.\d+\.\d+-x64\.\d+\.msi' } `
            | Sort-Object -Property href -Descending `
            | Select-Object -First 1
            $AzPSurl = $Latest.href
            $File = "$env:TEMP\$(Split-Path $AzPSurl -Leaf)"
            Invoke-WebRequest -Uri $AzPSurl -OutFile $File -Verbose
            $AzInstallerArgs = @{
                FilePath     = 'msiexec.exe'
                ArgumentList = @(
                    "/i $File",
                    "/qr",
                    "/l* $env:TEMP\Az-Cmdlets.log"
                )
                Wait         = $true
            }
            Start-Process @AzInstallerArgs -NoNewWindow
        }
        if (!($AzConnect = Connect-AzAccount -Verbose)) {
            Write-Host "Not logged in to Azure, logging in..." -ForegroundColor Yellow
            $AzConnect.Context ; Write-Host 'Azure Subscription details:' -ForegroundColor Cyan ; Get-AzSubscription
        }
        $AutomationAccount = Get-AzAutomationAccount `
            -Name $AutomationAccountName `
            -ResourceGroupName $ResourceGroupName
        if (-not $AutomationAccount) {
            throw "Automation account not found. Please check the name and resource group name."
        }
    }
    PROCESS {
        Write-Verbose -Message "Checking if the runbook already exists..."
        $Runbook = Get-AzAutomationRunbook -Name $RunbookName `
            -AutomationAccountName $AutomationAccountName `
            -ResourceGroupName $ResourceGroupName `
            -ErrorAction SilentlyContinue `
            -Verbose           
        if ($Runbook) {
            if ($Overwrite) {
                Remove-AzAutomationRunbook -Name $RunbookName `
                    -AutomationAccountName $AutomationAccountName `
                    -ResourceGroupName $ResourceGroupName `
                    -Force `
                    -Verbose
            }
            else {
                throw "Runbook already exists and -Overwrite switch not specified"
            }
        }
        Write-Host "VERBOSE: Script contents;" -ForegroundColor Green
        (Get-Content -Path $Path -Raw -Force -Verbose)
        $Runbook = New-AzAutomationRunbook -Name $RunbookName `
            -AutomationAccountName $AutomationAccountName `
            -ResourceGroupName $ResourceGroupName `
            -Description $Description `
            -Type $Type `
            -Verbose         
        if ($Publish) {
            Write-Verbose -Message "Publishing runbook, please wait..."
            Publish-AzAutomationRunbook -Name $RunbookName `
                -AutomationAccountName $AutomationAccountName `
                -ResourceGroupName $ResourceGroupName `
                -Verbose
        }
        if ($ImportRunbook) {
            Write-Verbose -Message "Importing runbook, please wait..."
            Import-AzAutomationRunbook -Name $RunbookName `
                -AutomationAccountName $AutomationAccountName `
                -ResourceGroupName $ResourceGroupName `
                -Description $Description `
                -Path $ImportRunbook `
                -Type $Type `
                -Force `
                -Verbose
        }
    }
    END {
        Write-Verbose -Message "Finished, closing connection..."
        Disconnect-AzAccount -Verbose
    }
}