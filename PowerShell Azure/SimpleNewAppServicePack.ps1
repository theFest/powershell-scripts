Function SimpleNewAppServicePack {
    <#
    .SYNOPSIS
    Creates a new Azure App Service and deploys a web app package.

    .DESCRIPTION
    This function creates a new Azure App Service and deploys a web app package. It supports various options to configure the app service, such as the app service plan tier, managed pipeline mode, web sockets, and more.

    .PARAMETER WebAppAction
    NotMandatory - action to perform on the Azure App Service.
    .PARAMETER Subscription
    NotMandatory - Azure subscription to use for creating the app service.
    .PARAMETER Location
    NotMandatory - Azure region where the app service will be created.
    .PARAMETER Environment
    NotMandatory - environment to deploy the web app to. This can be 'Staging' or 'Production'.
    .PARAMETER InstanceNumber
    NotMandatory - the number of instances to create for the app service.
    .PARAMETER WebAppName
    NotMandatory - specifies the name of the web app to create.
    .PARAMETER ResourceGroupName
    NotMandatory - name of the resource group to create for the app service.
    .PARAMETER AppServicePlanTier
    NotMandatory - pricing tier for the app service plan. This can be 'Free', 'Shared', 'Basic', 'Standard', 'Premium', or 'Isolated'.
    .PARAMETER ManagedPipelineMode
    NotMandatory - managed pipeline mode for the app service. This can be 'Integrated' or 'Classic'.
    .PARAMETER WebSocketsEnabled
    NotMandatory - specifies whether web sockets are enabled for the app service.
    .PARAMETER AlwaysOn
    NotMandatory - specifies whether Always On is enabled for the app service.
    .PARAMETER HttpsOnly
    NotMandatory - specifies whether HTTPS Only is enabled for the app service.
    .PARAMETER MinTlsVersion
    NotMandatory - minimum TLS version required for the app service. This can be '1.0', '1.1', or '1.2'.
    .PARAMETER Http20Enabled
    NotMandatory - specifies whether HTTP/2.0 is enabled for the app service.
    .PARAMETER AsJob
    NotMandatory - runs the function as a background job. The output of the function is stored in the job object.
    
    .EXAMPLE
    SimpleNewAppServicePack -Verbose
    SimpleNewAppServicePack -WebAppAction Publish -Subscription "My Subscription" -Location "East US" -Environment Production -InstanceNumber 1 -WebAppName "MyWebApp" `
    -ResourceGroupName "MyResourceGroup" -AppServicePlanTier Standard -ManagedPipelineMode Integrated -WebSocketsEnabled $true -AlwaysOn $true -HttpsOnly $true -MinTlsVersion 1.2 -Http20Enabled $true
    
    .NOTES
    v0.7.9
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("NewApp", "StopApp", "StartApp", "RestartApp", "RemoveApp")]
        [string]$WebAppAction = "NewApp",

        [Parameter(Mandatory = $false)]
        [string]$Subscription = "Visual Studio Professional Subscription",

        [Parameter(Mandatory = $false)]
        [ValidateSet("West Europe", "North Europe", "West US", "East US", "Central US" , "Southeast Asia", "Brazil South")]
        [string]$Location = "West Europe",
    
        [Parameter(Mandatory = $false)]
        [ValidateSet("dev", "test", "stage", "prod")]
        [string]$Environment = "dev",
    
        [Parameter(Mandatory = $false)]
        [ValidateRange("01", "99")]
        [string]$InstanceNumber = "01",
    
        [Parameter(Mandatory = $false)]
        [string]$WebAppName = "adf$(Get-Random)",
    
        [Parameter(Mandatory = $false)]
        [string]$ResourceGroupName = "rg-$WebAppName-$Environment-$InstanceNumber",
    
        [Parameter(Mandatory = $false)]
        [ValidateSet("Free", "Shared", "Basic", "Standard", "Premium")]
        [string]$AppServicePlanTier = "Standard",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Off", "On")]
        [string]$ManagedPipelineMode = "On",

        [Parameter(Mandatory = $false)]
        [ValidateSet("On", "Off", "Auto")]
        [string]$WebSocketsEnabled = "Auto",

        [Parameter(Mandatory = $false)]
        [ValidateSet("On", "Off")]
        [string]$AlwaysOn = "Off",

        [Parameter(Mandatory = $false)]
        [ValidateSet($true, $false)]
        [string]$HttpsOnly = "On",

        [Parameter(Mandatory = $false)]
        [ValidateSet("1.0", "1.1", "1.2", "1.3")]
        [string]$MinTlsVersion = "1.2",

        [Parameter(Mandatory = $false)]
        [ValidateSet("On", "Off")]
        [string]$Http20Enabled = "Off",
    
        [switch]$AsJob
    )
    BEGIN {
        if (!(Get-Package -Name "Az" -ErrorAction SilentlyContinue)) {
            Write-Verbose -Message "PowerShell Azure is missing..."
            [Net.ServicePointManager]::SecurityProtocol = "tls12, tls13"
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
        Write-Verbose -Message "Checking authentification context against Azure..."
        if (!(Get-AzContext)) {
            Write-Host "You're not connected to Azure, please login interactively..." -ForegroundColor Yellow
            Connect-AzAccount -Verbose
        }
    }
    PROCESS {
        if (!($ResourceGroupName)) {
            Write-Warning -Message "Resource group '$ResourceGroupName' does not exist, exiting..."
            break ; Disconnect-AzAccount -Verbose 
        }
        switch ($WebAppAction) {
            "NewApp" {
                $AppServiceName = "app-$WebAppName-$Environment-$InstanceNumber"
                $AppServicePlanName = "asp-$WebAppName-$Environment-$InstanceNumber"
                $StorageAccountName = ("st$WebAppName$Environment$InstanceNumber").ToLower().Replace("-", "")
                $ApplicationInsightsName = "ai-$WebAppName-$Environment-$InstanceNumber"
                $AnalyticsWorkspaceName = "log-$WebAppName-$Environment-$InstanceNumber"
                $Props = @{
                    Location          = $Location
                    ResourceGroupName = $ResourceGroupName
                }
                if (Get-AzResourceGroup @Props -ErrorAction SilentlyContinue) {
                    Write-Verbose -Message "Resource group '$ResourceGroupName' exists, deleting it..."
                    Remove-AzResourceGroup -Name $ResourceGroupName -Force -Verbose
                }   
                Write-Verbose -Message "Resource group '$ResourceGroupName' does not exist, creating it..."
                New-AzResourceGroup @Props -Verbose
                if (!(Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ErrorAction SilentlyContinue)) {
                    Write-Verbose -Message "Creating storage account '$StorageAccountName'..."
                    New-AzStorageAccount -ResourceGroupName $ResourceGroupName -Location $Location -Name $StorageAccountName -SkuName Standard_ZRS -Kind StorageV2 -AssignIdentity
                    $StorageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value
                }
                if (!(Get-AzResource -ResourceName $ApplicationInsightsName -ResourceType "Microsoft.Insights/components" -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue)) {
                    Write-Verbose -Message "Application Insights resource '$ApplicationInsightsName' does not exist, creating it..."
                    New-AzResource -Location $Location -Properties @{test = "test" } -ResourceName $ApplicationInsightsName `
                        -ResourceType "Microsoft.Insights/components" -ResourceGroupName $ResourceGroupName -Force
                }
                if (!(Get-AzOperationalInsightsWorkspace -Name $AnalyticsWorkspaceName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue)) {
                    Write-Verbose -Message "Log Analytics workspace '$AnalyticsWorkspaceName' does not exist, creating it..."
                    New-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $AnalyticsWorkspaceName -Location $Location -Verbose
                }
                if (!(Get-AzWebApp -Name $AppServiceName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue)) {
                    Write-Host "Creating new App Service: $AppServiceName in $Location, with App Service Plan: $AppServicePlanName ($AppServicePlanTier) in resource group: $ResourceGroupName"
                    New-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppServiceName -Location $Location -AppServicePlan $AppServicePlanName
                }
                Write-Verbose -Message "Configuring web app '$AppServiceName'..."
                $AiKey = (Get-AzResource -ResourceType "Microsoft.Insights/components" -ResourceGroupName $ResourceGroupName -Name $ApplicationInsightsName).Properties.InstrumentationKey
                $WebAppSettings = @{
                    "WebSocketsEnabled"                       = $WebSocketsEnabled
                    "AlwaysOn"                                = $AlwaysOn
                    "Http20Enabled"                           = $Http20Enabled
                    "ManagedPipelineMode"                     = $ManagedPipelineMode
                    "MinTlsVersion"                           = $MinTlsVersion
                    "APPINSIGHTS_INSTRUMENTATIONKEY"          = $AiKey
                    "APPLICATIONINSIGHTS_CONNECTION_STRING"   = "InstrumentationKey=$AiKey"
                    "APPLICATIONINSIGHTS_SAMPLING_PERCENTAGE" = "50"
                    "WEBSITE_DNS_SERVER"                      = "168.63.129.16"
                    "AzureStorageConfig__ImageContainer"      = "images";
                    "AzureStorageConfig__AccountName"         = $StorageAccountName
                    "AzureStorageConfig__ThumbnailContainer"  = "thumbnails"
                    "AzureStorageConfig__AccountKey"          = $StorageAccountKey
                }
                Set-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppServiceName -AppSettings $WebAppSettings `
                    -ConnectionStrings @{ MyStorageConnStr = @{ Type = "Custom"; Value = "DefaultEndpointsProtocol=https;AccountName=$StorageAccountName;AccountKey=$StorageAccountKey;" } }
                New-AzResource -PropertyObject $WebAppSettings -ResourceGroupName $ResourceGroupName `
                    -ResourceType Microsoft.Web/sites/config -ResourceName "$AppServiceName/metadata" -ApiVersion 2018-02-01 -Force
            }
            "StopApp" {
                Stop-AzWebApp -ResourceGroupName $ResourceGroupName -Name $WebAppName
            }
            "StartApp" {
                Start-AzWebApp -ResourceGroupName $ResourceGroupName -Name $WebAppName
            }
            "RestartApp" {
                Restart-AzWebApp -ResourceGroupName $ResourceGroupName -Name $WebAppName
            }
            "RemoveApp" {
                Remove-AzWebApp -ResourceGroupName $ResourceGroupName -Name $WebAppName -DeleteAppServicePlan -Force
            }
        }
    }
    END {
        Write-Verbose -Message "Disconnecting from Azure!"
        Disconnect-AzAccount -Verbose
    }
}