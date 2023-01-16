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
        [switch]$Publish = $false) {
        Get-AzAutomationAccount -Name $this.AutomationAccountName `
            -ResourceGroupName $this.ResourceGroupName `
            -Verbose
        $Runbook = Get-AzAutomationRunbook -Name $RunbookName `
            -AutomationAccountName $this.AutomationAccountName `
            -ResourceGroupName $this.ResourceGroupName `
            -ErrorAction SilentlyContinue

        if ($Runbook) {
            if ($Overwrite) {
                Remove-AzAutomationRunbook -Name $RunbookName `
                    -AutomationAccountName $this.AutomationAccountName `
                    -ResourceGroupName $this.ResourceGroupName `
                    -Verbose
            }
            else {
                throw "Runbook already exists and -Overwrite switch not specified"
            }
        }
        Get-Content $Path -Raw -Force -Verbose
        $Runbook = New-AzAutomationRunbook -Name $RunbookName `
            -AutomationAccountName $this.AutomationAccountName `
            -ResourceGroupName $this.ResourceGroupName `
            -Type $Type `
            -Description $Description
        Set-AzAutomationRunbook -Name $RunbookName `
            -ResourceGroupName $this.ResourceGroupName `
            -AutomationAccountName $this.AutomationAccountName `
            -Verbose
        if ($Publish) {
            Publish-AzAutomationRunbook -Name $RunbookName `
                -AutomationAccountName $this.AutomationAccountName `
                -ResourceGroupName $this.ResourceGroupName `
                -Verbose
        }
    }
}

Function UploadRunbookToAzureAutomation {
    <#
    .SYNOPSIS
    Upload Azure Automation Runbook.
    
    .DESCRIPTION
    With this Function you can create, upload and publish Runbook with it's script.
    
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
    .PARAMETER Publish
    NotMandatory - choose if runbook should be published after uploading.
    .PARAMETER Overwrite
    NotMandatory - if runbook already exists, it will be overwritten with this switch.
    
    .EXAMPLE
    "your_RunBook" | UploadRunbookToAzureAutomation -Path "your_local_script_path" -AutomationAccountName "your_az_automationaccountname" -ResourceGroupName "your_resource_group" -Description "some_description" -Type PowerShell -Publish -Overwrite -Verbose
    UploadRunbookToAzureAutomation -RunbookName "your_RunBook" -Path "your_local_script_path" -AutomationAccountName "your_az_automationaccountname" -ResourceGroupName "your_resource_group" -Description "some_description" -Type PowerShell -Publish -Overwrite -Verbose
    
    .NOTES
    v1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$RunbookName,

        [Parameter(Mandatory = $true)]
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
        [switch]$Publish = $false,

        [Parameter(Mandatory = $false)]
        [switch]$Overwrite
    )
    BEGIN {
        Write-Verbose -Message "Starting, prechecks in progress..."
        if (!(Get-Package -Name "Az" -ErrorAction SilentlyContinue)) {
            [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls, ssl3"
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
        if (!(Connect-AzAccount)) {
            Write-Output "Not logged in to Azure, logging in..."
            Connect-AzAccount -Verbose
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
            -Verbose `
            -ErrorAction SilentlyContinue
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
        (Get-Content $Path -Raw -Force -Verbose)
        $Runbook = New-AzAutomationRunbook -Name $RunbookName `
            -AutomationAccountName $AutomationAccountName `
            -ResourceGroupName $ResourceGroupName `
            -Type $Type `
            -Description $Description
        if ($Publish) {
            Write-Verbose -Message "Publishing runbook, please wait..."
            Publish-AzAutomationRunbook -Name $RunbookName `
                -AutomationAccountName $AutomationAccountName `
                -ResourceGroupName $ResourceGroupName `
                -Verbose
        }
    }
    END {
        Write-Verbose -Message "Finished, closing connection..."
        Disconnect-AzAccount -Verbose
    }
}