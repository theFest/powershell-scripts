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
  v1.0.1
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
    Write-Verbose -Message "Checking for PS Az Modules..."
    if (!(Get-InstalledModule -Name "Az")) {
      Write-Verbose -Message "Installing the Az PowerShell module..."
      try {
        Install-Module -Name "Az" -Scope CurrentUser -Verbose
      }
      catch {
        Write-Error "Failed to import 'Az' module. Error: $_"
        return
      }
    }
    Write-Warning -Message "Checking authentification context against Azure..."
    if (!(Get-AzContext -ErrorAction SilentlyContinue)) {
      try {
        Connect-AzAccount -ErrorAction Stop
      }
      catch {
        Write-Error "Failed to authenticate user. Error: $_"
        return
      }
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