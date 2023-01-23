Class AzureAutomationRunbook {
    [string]$AutomationAccountName
    [string]$ResourceGroupName
    AzureAutomationRunbook(
        [string]$AutomationAccountName,
        [string]$ResourceGroupName) {
        $this.AutomationAccountName = $AutomationAccountName
        $this.ResourceGroupName = $ResourceGroupName
    }
    [string] Start([string]$RunbookName, [hashtable]$Params, [switch]$WaitForComplete) {
        $JobId = Start-AzAutomationRunbook -AutomationAccountName $this.AutomationAccountName `
            -Name $RunbookName `
            -ResourceGroupName $this.ResourceGroupName `
            -Parameters $Params `
            -ErrorAction Stop

        if ($WaitForComplete) {
            Wait-AzAutomationJob -Id $JobId `
                -AutomationAccountName $this.AutomationAccountName `
                -ResourceGroupName $this.ResourceGroupName `
                -Verbose
            $Job = Get-AzAutomationJob -Id $JobId `
                -AutomationAccountName $this.AutomationAccountName `
                -ResourceGroupName $this.ResourceGroupName
            return $Job.Status
        }
        return $JobId
    }
}

Function StartAzAutomationRunbook {
    <#
    .SYNOPSIS
    Start Runbook on Azure Automation.
    
    .DESCRIPTION
    This function is used to start a runbook on an Azure Automation account. 
    
    .PARAMETER RunbookName
    Mandatory - name of the runbook that will be started.
    .PARAMETER Params
    Mandatory - parameters that will be passed to the runbook that will be started.
    .PARAMETER AutomationAccountName
    Mandatory - the name of the automation account that the runbook will start on.
    .PARAMETER ResourceGroupName
    Mandatory - name of the resource group that the automation account is located in.
    .PARAMETER WaitForCompletion
    NotMandatory - wait for runbook to complete.

    .EXAMPLE
    #$Params = @{ "ResourceGroupName" = "rg-application-reg-env-instance" }
    StartAzAutomationRunbook -RunbookName "your_AzRunBook" -AutomationAccountName "your_AzAutomationName" -ResourceGroupName "AzAuto" -Params $Params -WaitForCompletion -Verbose
    
    .NOTES
    v1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$RunbookName,

        [Parameter(Mandatory = $true)]
        [hashtable]$Params,

        [Parameter(Mandatory = $true)]
        [string]$AutomationAccountName,

        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName,

        [Parameter()]
        [switch]$WaitForCompletion
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
    }
    PROCESS {
        Write-Verbose -Message "Starting RunBook on Azure Automation..."
        $AutomationRunbook = [AzureAutomationRunbook]::new($AutomationAccountName, $ResourceGroupName)
        $OutputStatus = $AutomationRunbook.Start($RunbookName, $Params, $WaitForCompletion)
        Write-Output $OutputStatus
    }
    END {
        Write-Verbose -Message "Finished, Execution of StartAzAutomationRunbook function completed closing connection..."
        Disconnect-AzAccount -Verbose
    }
}