Function Get-SecurityEvents {
      <#
      .SYNOPSIS
      Searches for security events based on specified criteria and saves the results to a CSV file.
  
      .DESCRIPTION
      This function retrieves security events from a specified Domain Controller based on various event IDs related to user accounts, computer accounts, security groups, distribution groups, application groups, and other account management activities. The results are saved to a CSV file and can be emailed if desired.
  
      .PARAMETER Hours
      Specifies the number of hours to search back for security events.
      .PARAMETER OutputFolder
      Folder where the found security events will be saved in a CSV file.
      .PARAMETER ToEmailAddress
      Email address to which the results will be sent.
      .PARAMETER FromEmailAddress
      Email address from which the results will be sent.
      .PARAMETER SmtpServer
      The SMTP server to use for sending email.
  
      .EXAMPLE
      Get-SecurityEvents -Hours 24 -OutputFolder "C:\SecurityLogs" -ToEmailAddress "admin@example.com" -FromEmailAddress "noreply@example.com" -SmtpServer "smtp.example.com"
  
      .NOTES
      -v0.0.1
      - Event ID details can be found at: https://www.ultimatewindowssecurity.com/securitylog/book/page.aspx?spid=chapter8
      #>
      [CmdletBinding()]
      param (
          [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Number of hours to search back")]
          [string]$Hours,
  
          [Parameter(Mandatory = $true, Position = 1, HelpMessage = "Folder for storing found events")]
          [string]$OutputFolder,
  
          [Parameter(Mandatory = $False, Position = 2, HelpMessage = "Enter email-address to send the logs to")]
          [string]$ToEmailAddress,
  
          [Parameter(Mandatory = $False, Position = 3, HelpMessage = "Enter the From Address")]
          [string]$FromEmailAddress,
  
          [Parameter(Mandatory = $False, Position = 4, HelpMessage = "Enter the SMTP server to use")]
          [string]$SmtpServer
      )
      Write-Verbose -Message "Testing admin privileges without using -Requires RunAsAdministrator,"
      if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
          Write-Warning -Message ("Function {0} needs admin privileges, aborting..." -f $MyInvocation.MyCommand)
          return
      }
      Write-Verbose -Message "Getting Domain Controller with PDC FSMO Role to get events from"
      try {
          $DomainController = (Get-ADDomain).PDCEmulator
      }
      catch {
          Write-Warning -Message "Unable to get Domain information, check ActiveDirectory module installation, aborting!"
      }
      $UserAccountManagementEventids = 
      4720, #--> user account was created
      4722, #--> user account was enabled
      4723, #--> attempt was made to change an account's password
      4724, #--> attempt was made to reset an accounts password
      4725, #--> user account was disabled
      4726, #--> user account was deleted
      4738, #--> user account was changed
      4740, #--> user account was locked out
      4767, #--> user account was unlocked
      4780, #--> ACL was set on accounts which are members of administrators groups
      4781, #--> name of an account was changed
      4794, #--> attempt was made to set the directory services restore mode administrator password
      5376, #--> credential manager credentials were backed up
      5377  #--> credential Manager credentials were restored from a backup
      $ComputerAccountManagementEventids = 
      4741, #--> computer account was created
      4742, #--> computer account was changed
      4743  #--> computer account was deleted
      $SecurityGroupManagementEventids =
      4727, #--> security-enabled global group was created
      4728, #--> member was added to a security-enabled global group
      4729, #--> member was removed from a security-enabled global group
      4730, #--> security-enabled global group was deleted
      4731, #--> security-enabled local group was created
      4732, #--> member was added to a security-enabled local group
      4733, #--> member was removed from a security-enabled local group
      4734, #--> security-enabled local group was deleted
      4735, #--> security-enabled local group was changed
      4737, #--> security-enabled global group was changed
      4754, #--> security-enabled universal group was created
      4755, #--> security-enabled universal group was changed
      4756, #--> member was added to a security-enabled universal group
      4757, #--> member was removed from a security-enabled universal group
      4758, #--> security-enabled universal group was deleted
      4764  #--> groups type was changed
      $DistributionGroupManagementEventids =
      4744, #--> security-disabled local group was created
      4745, #--> security-disabled local group was changed
      4746, #--> member was added to a security-disabled local group
      4747, #--> member was removed from a security-disabled local group
      4748, #--> security-disabled local group was deleted
      4749, #--> security-disabled global group was created
      4750, #--> security-disabled global group was changed
      4751, #--> member was added to a security-disabled global group
      4752, #--> member was removed from a security-disabled global group
      4753, #--> security-disabled global group was deleted
      4759, #--> security-disabled universal group was created
      4760, #--> security-disabled universal group was changed
      4761, #--> member was added to a security-disabled universal group
      4762, #--> member was removed from a security-disabled universal group
      4763  #--> security-disabled universal group was deleted
      $ApplicationGroupManagementEventids =
      4783, #--> basic application group was created
      4784, #--> basic application group was changed
      4785, #--> member was added to a basic application group
      4786, #--> member was removed from a basic application group
      4787, #--> non-member was added to a basic application group
      4788, #--> non-member was removed from a basic application group
      4789, #--> basic application group was deleted
      4790, #--> an LDAP query group was created
      4791, #--> basic application group was changed
      4792  #--> an LDAP query group was deleted
      $OtherAccountManagementEventids =
      4739, #--> domain policy was changed
      4793  #--> the password policy checking API was called
      Write-Verbose -Message "Setting date and eventids..."
      $Date = (Get-Date).AddHours( - $($Hours))   
      $FilterUserAccountManagement = @{
          Logname   = "Security"
          ID        = $UserAccountManagementEventids
          StartTime = $Date
          EndTime   = [datetime]::Now
      }
      $FilterComputerAccountManagement = @{
          Logname   = "Security"
          ID        = $ComputerAccountManagementEventids
          StartTime = $Date
          EndTime   = [datetime]::Now
      }
      $FilterSecurityGroupManagement = @{
          Logname   = "Security"
          ID        = $SecurityGroupManagementEventids
          StartTime = $Date
          EndTime   = [datetime]::Now
      }
      $FilterDistributionGroupManagement = @{
          Logname   = "Security"
          ID        = $DistributionGroupManagementEventids
          StartTime = $Date
          EndTime   = [datetime]::Now
      }
      $FilterApplicationGroupManagement = @{
          Logname   = "Security"
          ID        = $ApplicationGroupManagementEventids
          StartTime = $Date
          EndTime   = [datetime]::Now
      }
      $FilterOtherAccountManagement = @{
          Logname   = "Security"
          ID        = $OtherAccountManagementEventids
          StartTime = $Date
          EndTime   = [datetime]::Now
      }
      Write-Host ("Retrieving Security events from {0}..." -f $DomainController) -ForegroundColor Green
      $Collection = foreach ($EventIDs in `
              $FilterUseraccountManagement, `
              $FilterComputerAccountManagement, `
              $FilterSecurityGroupManagement, `
              $FilterDistributionGroupManagement, `
              $FilterApplicationGroupManagement, `
              $FilterOtherAccountManagement ) {
          $Events = Get-WinEvent -FilterHashtable $EventIDs -ComputerName $DomainController -ErrorAction SilentlyContinue 
          foreach ($Event in $Events) {
              Write-Host ("- Found EventID {0} on {1} and adding to list..." -f $Event.id, $Event.TimeCreated) -ForegroundColor Green
              [PSCustomObject]@{
                  DomainController = $DomainController
                  Timestamp        = $Event.TimeCreated
                  LevelDisplayName = $Event.LevelDisplayName
                  EventId          = $Event.Id
                  Message          = $Event.message -replace '\s+', " "
              }
          }
      }
      if ($null -ne $Collection) {
          $FilenameTimestamp = Get-Date -Format 'dd-MM-yyyy-HHmm'
          Write-Host ("- Saving the {0} events found to {1}..." -f $Collection.count, "$($OutputFolder)\events_$($FilenameTimestamp).csv") -ForegroundColor Green
          $Collection | Sort-Object TimeStamp, DomainController, EventId | Export-Csv -Delimiter ';' -NoTypeInformation -Path "$($OutputFolder)\events_$($FilenameTimestamp).csv"
          if ($ToEmailAddress) {
              $EmailOptions = @{
                  Attachments = "$($OutputFolder)\events_$($FilenameTimestamp).csv"
                  Body        = "See Attached CSV file"
                  ErrorAction = "Stop"
                  From        = $FromEmailAddress
                  Priority    = "High" 
                  SmtpServer  = $SmtpServer
                  Subject     = "Security event found"
                  To          = $ToEmailAddress
              }
              Write-Host ("- Emailing the {0} events found to {1}..." -f $Collection.count, $ToEmailAddress) -ForegroundColor Green
              try {
                  Send-MailMessage @EmailOptions -Verbose
              }
              catch {
                  Write-Warning -Message "Unable to email results, please check the email settings..."
              }
          }
      }
  }
  