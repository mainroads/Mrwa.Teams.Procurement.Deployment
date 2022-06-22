#
# This script provisions IDD project and contractors Teams for Procurement team 
#
### Prerequisites ###  
#
# 1. Assign following roles to user account running this script
#     * Application Administrator (To register PnP Management Shell Azure AD application)
#     * SharePoint Administrator (To create SharePoint sites)
#     * The MRWA group who are allowed to create groups
#
# 2. Register PnPManagementShellAccess Azure AD application prior to running this script for the first time. Script will also need additional graph api permission to auto provision the private channel sites.    
#    This script will automatically check for "PnP Management Shell" Azure AD App and will create new one if it do not already exist using consent flow.
#
#    Failing to register this application prior to running the script will result in the following error:       
#    Connect-PnPOnline : AADSTS65001: The user or administrator has not consented to use the application with ID '31359c7f-bd7e-475c-86db-fdb8c937548e' named 'PnP Management Shell'. 
#                        Send an interactive authorization request for this user and resource
#
# 3. Verify and set the configuration parameters and input files as necessary 
#    Note:  * teamPrefix
#           * teamSuffix
#           * UserPrincipalName for Team Owners in Project_Team.xml, Contractors_Team.xml 
#           * Project_Team_Folder_Structure.csv
#           * Contractors_Team_Folder_Structure.csv
#
### Provisioning Instructions ### 
# 1. Ensure prerequisites are completed
# 2. Browse to the project directory
#     cd "<project_location_in_file_system>\.Mrwa.Teams.Procurement.Deployment"
# 3. Execute Create-ProcurementTeams.ps1
#     Syntax: .\Create-ProcurementTeams.ps1 -M365Domain <domain_name> -ProjectName <project_name> -ProjectNumber <project_number> -ProjectAbbreviation <project_abbreviation> -ContractType <contract_type> -TeamType <Team_Type> [-NoFolderCreation] 
#
### Provisioning Procedure ###

# Step : Run the below command to start the scrip whhich will auto provision the team and channels including folders by default  (Team and channels including subfolders)
# Incase the folders are not required to be provisioned then just use the flag [-NoFolderCreation] which will skip the folder creation steps.
# 
# Note:
#   1. In case script fails while running, just run the command again with the same command to continue the provisioning process 
# 
#

Param(
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $M365Domain,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $ProjectName,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $ProjectNumber,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]
  $ProjectAbbreviation,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [ValidateSet(
    "Alliance",
    "D&C",
    IgnoreCase = $true)]
  [string]
  $ContractType,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [ValidateSet(
    "Project",
    "Contractors",
    IgnoreCase = $true)]
  [string]
  $TeamType,

  [switch]
  $NoFolderCreation = $false
)

$ErrorActionPreference = "Stop"

$scriptStart = Get-Date

#--------------------
# Install Dependencies if not already present in current workspace
#--------------------

Get-PackageProvider -Name Nuget -ForceBootstrap
Import-Module PnP.PowerShell -Scope Local -DisableNameChecking

$pnpPowerShellAppName = "PnP Management Shell"

#--------------------
# Configuration
#--------------------

# Teams:

$adminUrl = "https://$($M365Domain)-admin.sharepoint.com/"
$teamPrefix = "MR"
$teamSuffix = if ($TeamType -eq "Project") { "PRJ" } else { "CON" }
$foldersCsvFileRelativePath = "Seed\$($TeamType)_Team_Folder_Structure.csv"

#--------------------
# Main
#--------------------

# Connect to SharePoint:
Connect-PnPOnline -Url $adminUrl -Interactive

$pnpPowerShellApp = Get-PnPAzureADApp -Identity $pnpPowerShellAppName -ErrorAction SilentlyContinue

if($null -eq $pnpPowerShellApp){

  $graphPermissions = "Group.Read.All","Group.ReadWrite.All","Directory.Read.All",
  "Directory.ReadWrite.All","Channel.ReadBasic.All","ChannelSettings.Read.All",
  "ChannelSettings.ReadWrite.All","Channel.Create","Team.ReadBasic.All","TeamSettings.Read.All",
  "TeamSettings.ReadWrite.All","User.ReadWrite.All","Group.Read.All"

  $sharePointApplicationPermissions = "Sites.FullControl.All","User.ReadWrite.All"

  $sharePointDelegatePermissions = "AllSites.FullControl"

  Register-PnPAzureADApp -ApplicationName $pnpPowerShellAppName -Tenant contosostakeholder.onmicrosoft.com -OutPath c:\development -DeviceLogin -GraphApplicationPermissions $graphPermissions -SharePointApplicationPermissions $sharePointApplicationPermissions -SharePointDelegatePermissions $sharePointDelegatePermissions

}

$parameters = @{
  "TeamPrefix"          = $teamPrefix
  "TeamSuffix"          = $teamSuffix
  "ProjectNumber"       = $ProjectNumber
  "ProjectAbbreviation" = $ProjectAbbreviation
  "ProjectName"        = $ProjectName
}

# Invoke template to create Team, Channels

$stopInvokingTemplate = $false
$retryCount = 0
$maxRetryCount = 3 

do {
  try {
      
    if ($TeamType -eq "Project") {
      Invoke-PnPTenantTemplate -Path "Templates\Project_Team.xml" -Parameters $parameters
    }
    elseif ($TeamType -eq "Contractors") {
      Invoke-PnPTenantTemplate -Path "Templates\Contractors_Team.xml" -Parameters $parameters 
    }
    else {
       Invoke-PnPTenantTemplate -Path "Templates\Project_Team.xml" -Parameters $parameters 
       Invoke-PnPTenantTemplate -Path "Templates\Contractors_Team.xml" -Parameters $parameters 
    }

      $stopInvokingTemplate = $true
  }
  catch {
      if ($retryCount -gt $maxRetryCount) {        
          $stopInvokingTemplate = $true
      }
      else {
          Start-Sleep -Seconds 30
          $retryCount = $retryCount + 1
          Write-Host "Something went wrong....retry attempt : $retryCount"
      }
  }
}
While ($stopInvokingTemplate -eq $false)


######### Wait for 3 minutes to teams provisioning to complete 100% #######################

$seconds = 180
1..$seconds |
ForEach-Object { $percent = $_ * 100 / $seconds; 

Write-Progress -Activity "Wait for 3 minutes before ensuring the private channel sharepoint sites provisioning" -Status "$($seconds - $_) seconds remaining..." -PercentComplete $percent; 

Start-Sleep -Seconds 1
}

########## Code to invoke private channel sites ###########################################

#Request graph access toeken
$accessToken = Get-PnPGraphAccessToken

#Get teams data via the Graph
Write-Host "Getting the newly created team details..." -ForegroundColor DarkYellow

$response = Invoke-RestMethod -Headers @{Authorization = "Bearer $accessToken" } -Uri "https://graph.microsoft.com/beta/teams?$filter=startswith(displayName, `'$($teamPrefix)-$($ProjectNumber)-$($ProjectAbbreviation)`')" -Method 'GET' -ContentType 'application/json'
 
#Select the data for each team
$team = $response.value[0] | Select-Object 'displayName', 'id'
 
try {

    #Get the channel
    $allChannels = (Invoke-RestMethod -Headers @{Authorization = "Bearer $accessToken" } -Uri "https://graph.microsoft.com/beta/teams/$($team.id)/channels" -Method 'GET' -ContentType 'application/json').value | Select-Object 'displayName', 'id'
    
    #Attempt channel check
    $stopLoop = $false
    $retryCount = 0
    $maxRetryCount = 10   
   
    #Trigger private channel SharePoint Onlinesite creation
    foreach ($channel in $allChannels) {
        do {
            try {
                Invoke-RestMethod -Headers @{Authorization = "Bearer $accessToken" } -Uri "https://graph.microsoft.com/beta/teams/$($team.id)/channels/$($channel.id)/filesFolder" | Out-Null
                $stopLoop = $true
            }
            catch {
                if ($retryCount -gt $maxRetryCount) {
                    $stoploop = $true
                }
                else {
                    Start-Sleep -Seconds 5
                    $retryCount = $retryCount + 1
                }
            }
        }
        While ($stopLoop -eq $false)
    }
}
catch {
    Write-Host $_
}


if (!$NoFolderCreation) {
  # PnP Provisioning Schema currently does not have support for adding folders 
  # to private channels. Therefore, add folders explicitly using the following 
  # logic. Use this consistently to add folders for both standard and private
  # channels. This logic is not required when provisioning schema is updated 
  # in the later versions to add folders to private channels

  Write-Host "Starting with creating folders in to each channels" -ForegroundColor Green
  foreach ($folder in (import-csv $foldersCsvFileRelativePath)) {
    $channelPrivacy = $folder.Privacy
    $folderRelativePath = ($folder.Folder).Replace('XXX', $ProjectAbbreviation)
    $folderContractType = $folder.ContractType
  
    Write-Host `n"Processing: $folderRelativePath..." -ForegroundColor DarkMagenta

    if ($channelPrivacy -eq "Standard") {
      $siteUrl = "https://$($M365Domain).sharepoint.com/teams/$($teamPrefix)-$($ProjectNumber)-$($ProjectAbbreviation)-$($teamSuffix)"
    }
    elseif ($channelPrivacy -eq "Private") {
      $channel = $folderRelativePath.Substring(0,$folderRelativePath.IndexOf("/"))
      $siteUrl = "https://$($M365Domain).sharepoint.com/teams/$($teamPrefix)-$($ProjectNumber)-$($ProjectAbbreviation)-$($teamSuffix)-$($channel)"
    }

    Write-Host "Connecting to :" $siteUrl -ForegroundColor DarkGray
    Connect-PnPOnline -Url $siteUrl -Interactive

    if(($folderContractType -eq $ContractType) -or ($folderContractType -eq "Common")){
      Resolve-PnPFolder -SiteRelativePath "Shared Documents/$folderRelativePath"
    }
  }
}

$scriptEnd = Get-Date
$timeElapsed = New-TimeSpan -Start $scriptStart -End $scriptEnd

Write-Host
Write-Host "Started:`t" $scriptStart -ForegroundColor DarkGray
Write-Host "Finished:`t" $scriptEnd -ForegroundColor DarkGray
Write-Host "Duration:`t" $timeElapsed.ToString("hh\:mm\:ss") -ForegroundColor DarkGray
Write-Host