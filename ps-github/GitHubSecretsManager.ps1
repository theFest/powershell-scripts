Function GitHubSecretsManager {
    <#
    .SYNOPSIS
    Manage secrets stored in GitHub repositories using the GitHub API. It can be used to create, retrieve, update, and delete secrets.

    .DESCRIPTION
    This GitHubSecretsManager enables you to manage secrets stored in GitHub repositories using the GitHub API, you can use it to create, retrieve, update, and delete repository secrets, requires a GitHub personal access token with appropriate permissions.

    .PARAMETER Token
    Mandatory - GitHub personal access token to use for authentication, token must have the repo scope to access repository secrets.
    .PARAMETER Repository
    Mandatory - name of the repository where the secret is stored, this can be in the format owner/repo.
    .PARAMETER Operation
    Mandatory - operation to perform on the secret. Valid values are Create, Get, Update, and Delete.
    .PARAMETER Name
    NotMandatory - name of the secret that will be displayed in secrets section.
    .PARAMETER Value
    NotMandatory - specifies the value of the secret, for Create and Update operations, this parameter is mandatory.
    .PARAMETER Filename
    NotMandatory - filename for the secret, this is only required for the Create operation.
    .PARAMETER Force
    NotMandatory - indicates whether to overwrite an existing secret when creating a new one.
    .PARAMETER PassThru
    NotMandatory - returns the updated secret object after an Update operation.

    .EXAMPLE
    GitHubSecretsManager -Operation Get -Repository "https://github.com/your_user/your_repo" -Token "ghp_xyz" -Name "YOUR_TOKEN_NAME" -Verbose
    GitHubSecretsManager -Operation List -Repository "https://github.com/your_user/your_repo" -Token "ghp_xyz" -Verbose
    GitHubSecretsManager -Operation Create -Repository "https://github.com/your_user/your_repo" -Token "ghp_xyz" -Name "YOUR_TOKEN_NAME" -Value "YOUR_TOKEN_VALUE"
    GitHubSecretsManager -Operation Update -Repository "https://github.com/your_user/your_repo" -Token "ghp_xyz" -Name "YOUR_TOKEN_NAME" -Value "YOUR_NEW_TOKEN_VALUE"
    GitHubSecretsManager -Operation Delete -Repository "https://github.com/your_user/your_repo" -Token "ghp_xyz" -Name "YOUR_TOKEN_NAME" -Verbose

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Get", "List", "Create", "Update", "Delete")]
        [string]$Operation,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Token,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Repository,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Value,

        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )
    BEGIN {
        Write-Verbose -Message "Checking for Chocolatey..."
        if (-not(Get-Command choco.exe -ErrorAction SilentlyContinue)) {
            try {
                Write-Verbose -Message "Installing Chocolatey..."
                Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
            }
            catch {
                Write-Error "Failed to install Chocolatey: $($_.Exception.Message)"
                return
            }
        }
        Write-Verbose -Message "Installing Git and GitHub CLI using Chocolatey"
        if (-not(Get-Command git -ErrorAction SilentlyContinue)) {
            try {
                choco install git -y
                Write-Host "Git CLI installation successful" -ForegroundColor Green
            }
            catch {
                Write-Error "Failed to install Git CLI: $($_.Exception.Message)"
            }
        }
        if (-not(Get-Command gh -ErrorAction SilentlyContinue)) {
            try {
                choco install gh -y
                Write-Host "GitHub CLI installation successful" -ForegroundColor Green
            }
            catch {
                Write-Error "Failed to install GitHub CLI: $($_.Exception.Message)"
            }
        }
        Write-Verbose -Message "Checking if token is valid..."
        Set-Content -Value $Token -Path "$env:USERPROFILE\Desktop\ght.txt" -Force -Verbose
        Start-Process -FilePath "cmd" -ArgumentList "/c gh auth login --with-token < $env:USERPROFILE\Desktop\ght.txt" -WindowStyle Hidden -Wait
        Write-Verbose -Message "Logged in to GitHub, continuing with selected operation $($Operation)..."
    }
    PROCESS {
        $Owner, $RepositoryName = $Repository.Split("/")[-2, -1]
        $RepositoryUrl = "https://api.github.com/repos/$Owner/$RepositoryName"
        switch ($Operation) {
            "Get" {
                if (-not $Name) {
                    throw "Name is required for Get operation."
                }
                Write-Verbose -Message "Getting secret $Name..." ; $SecretUrl = "$RepositoryUrl/actions/secrets/$Name"
                $Secret = Invoke-RestMethod -Uri $SecretUrl -Method Get -Headers @{ Authorization = "Bearer $Token" } -ContentType "application/vnd.github.v3+json"
                if (!$Secret) {
                    throw "Secret with name '$Name' does not exist."
                }
                $SecretData = @{
                    Name      = $Secret.name
                    CreatedAt = $Secret.created_at
                    UpdatedAt = $Secret.updated_at
                    Value     = $null
                }
                if ($PassThru) {
                    $SecretData.Value = $Secret.value
                }
                return New-Object PSObject -Property $SecretData
            }
            "List" {
                Write-Verbose -Message "Listing all secrets..." ; $SecretsUrl = "$RepositoryUrl/actions/secrets"
                $Secrets = Invoke-RestMethod -Uri $SecretsUrl -Method Get -Headers @{ Authorization = "Bearer $Token" } -ContentType "application/vnd.github.v3+json"
                if (!$Secrets) {
                    throw "Failed to list secrets."
                }
                if ($PassThru) {
                    return $Secrets.secrets
                }
                $Secrets.secrets | Select-Object -Property name, created_at, updated_at | Format-Table -AutoSize
            }
            "Create" {
                if (-not $Name -or -not $Value) {
                    throw "Name, Value, and Filename are required for Create operation."
                }
                $Filename = "$env:USERPROFILE\Desktop\fsr.txt"
                if (!(Test-Path -Path $Filename)) {
                    New-Item -ItemType File -Path $Filename -Force -Verbose | Out-Null
                    Clear-Content -Path $Filename -Force -Verbose
                    Add-Content -Path $Filename -Value "$Name=$Value" -Force -Verbose
                }
                try {
                    if ($Confirm) {
                        $ConfirmMessage = "Are you sure you want to create secret $Name?"
                        $Confirmed = $Host.UI.PromptForChoice('Confirm', $ConfirmMessage, @( 'Yes', 'No' ), 1)
                        if ($Confirmed -eq 1) {
                            return
                        }
                    }
                    Write-Verbose -Message "Creating secret $Name..."
                    $Content = Get-Content $Filename | Out-String
                    gh secret set $Name --body="$Content" --repo="$Repository" > $null
                }
                catch {
                    throw "Failed to create secret '$Name'. $_"
                }
            }
            "Update" {
                if (-not $Name -or -not $Value) {
                    throw "Name, Value, and Filename are required for Update operation."
                }
                $Filename = "$env:USERPROFILE\Desktop\fsr.txt"
                if (!(Test-Path -Path $Filename)) {
                    Write-Warning -Message "The specified file '$Filename' does not exist, creating it..."
                    New-Item -ItemType File -Path $Filename -Force -Verbose | Out-Null
                    Clear-Content -Path $Filename -Force -Verbose
                    Add-Content -Path $Filename -Value "$Name=$Value" -Force -Verbose
                }
                try {
                    $Value = Get-Content $Filename | Out-String
                    Write-Verbose -Message "Updating secret $Name..."
                    $SecretsUrl = "$RepositoryUrl/actions/secrets"
                    $Secrets = Invoke-RestMethod -Uri $SecretsUrl -Method Get -Headers @{ Authorization = "Bearer $Token" } -ContentType "application/vnd.github.v3+json"
                    $Secret = $Secrets.secrets | Select-Object -Property name
                    if (!$Secret) {
                        throw "Secret with name '$Name' does not exist."
                    }
                    gh secret set $Name --body="$Value" --repo="$Repository" > $null
                }
                catch {
                    throw "Failed to update secret '$Name'. $_"
                }
            }
            "Delete" {
                if (-not $Name) {
                    throw "Name is required for Delete operation."
                }
                $SecretsUrl = "$RepositoryUrl/actions/secrets" ; $SecretUrl = "$SecretsUrl/$Name"
                try {
                    $Secret = gh api $SecretsUrl -H "Accept: application/vnd.github.v3+json" -H "Authorization: Bearer $Token" --paginate | Select-Object -Property name
                }
                catch {
                    throw "Failed to retrieve secret '$Name': $_"
                }
                try {
                    Invoke-RestMethod -Uri $SecretUrl -Method DELETE -Headers @{ Authorization = "Bearer $Token" } -ContentType "application/json" -ErrorAction Stop
                    Write-Host "Secret '$Name' deleted successfully" -ForegroundColor Green
                }
                catch {
                    throw "Failed to delete secret '$Name': $_ $($Error[0].Exception.Message)"
                }
            }
            default {
                throw "Invalid operation: $Operation specified. Use -Operation Create/Update/Delete/List!"
            }
        }
    }
    END {
        Write-Verbose -Message "Cleaning up, closing connection and exiting..."
        gh auth logout --hostname "github.com"
        Clear-History -Verbose -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:USERPROFILE\Desktop\fsr.txt" -Force -Verbose -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:USERPROFILE\Desktop\ght.txt" -Force -Verbose -ErrorAction SilentlyContinue
        Clear-Variable -Name Repository, Secret, Token, Name, Value -Scope Global -Force -Verbose -ErrorAction SilentlyContinue
        Remove-Variable -Name Repository, Secret, Token, Name, Value -Scope Global -Force -Verbose -ErrorAction SilentlyContinue
        Write-Host "Operation $($Operation) completed for repository: $($Repository)" -ForegroundColor Green
    }
}
