#
# This script provisions IDD project and contractors Teams for Procurement team 
#
### Pre-requistes ###  
#
# 1. Assign following roles  to user account running this script
#     * Application Administrator (To register PnP Management Shell Azure AD application)
#     * SharePoint Administrator (To create SharePoint sites)
#     * The MRWA group who are allowed to create groups
#
# 2. Register PnPManagementShellAccess Azure AD application prior to running this script for the first time.
#    Reference: https://pnp.github.io/powershell/articles/authentication.html
#    Failing to register this application prior to running the script will result in the following error:
#       
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
#     Syntax: .\Create-ProcurementTeams.ps1 -M365Domain <domain_name> -ProjectName <project_name> -ProjectNumber <project_number> -ProjectAbbreviation <project_abbreviation> -ContractType <contract_type> -TeamType <Team_Type> [-CreateFolders] [-InstallDependencies]
#
### Provisioning Procedure ###
# There are three steps to provision the Teams
# Step 1: Run Create-ProcurementTeams.ps1 without -CreateFolders switch. This creates the shell (Team and channels without subfolders)
# Step 2: Verify if the underlying SharePoint sites for Private Channels are created. If not, navigate to Files tab under each Private Channel in Team
# Step 3: Run Create-ProcurementTeams.ps1 with -CreateFolders switch 
# 
# Note:
#   1. Script sometimes exits after provisioning only standard channels. Run the command again with the same command to continue on with the private channels  
#   2. InstallDependencies: This switch installs NuGet packet manager and PnP.PowerShell modules necessary for running Apply-Template.ps1 script. Set this switch when the script is run for the first time.
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
  $CreateFolders = $false,

  [switch]
  $InstallDependencies = $false
)

$ErrorActionPreference = "Stop"

$scriptStart = Get-Date

#--------------------
# Dependencies
#--------------------

if ($InstallDependencies) {
  Install-PackageProvider -Name NuGet -Scope AllUsers -Force
  Install-Module -Name PnP.PowerShell -Scope AllUsers -Force
}

Import-Module PnP.PowerShell -Scope Local -DisableNameChecking

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

$parameters = @{
  "TeamPrefix"          = $teamPrefix
  "TeamSuffix"          = $teamSuffix
  "ProjectNumber"       = $ProjectNumber
  "ProjectAbbreviation" = $ProjectAbbreviation
  "ProjectName"        = $ProjectName
}

# Invoke template to create Team, Channels
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

# TODO: Add Graph API logic to simulate navigating to Files folder in Private Channels.
# Reference: https://www.tribework.nl/2022/03/howto-initialize-private-teamchannel-spo-sites/
# TODO: After adding Graph API logic, remove CreateFolders switch to execute script from end-to-en in one go.

if ($CreateFolders) {
  # PnP Provisioning Schema currently does not have support for adding folders 
  # to private channels. Therefore, add folders explicitly using the following 
  # logic. Use this consistently to add folders for both standard and private
  # channels. This logic is not required when provisioning schema is updated 
  # in the later versions to add folders to private channels

  foreach ($folder in (import-csv $foldersCsvFileRelativePath)) {
    $channelPrivacy = $folder.Privacy
    $folderRelativePath = ($folder.Folder).Replace('XXX', $ProjectAbbreviation)
    $channel = $folderRelativePath.Substring(0,$folderRelativePath.IndexOf("/"))
  
    Write-Host `n"Processing: $channel-$channelPrivacy-$folderRelativePath..." -ForegroundColor DarkMagenta

    if ($channelPrivacy -eq "Standard") {
      $siteUrl = "https://$($M365Domain).sharepoint.com/sites/$($teamPrefix)-$($ProjectNumber)-$($ProjectAbbreviation)-$($teamSuffix)"
    }
    elseif ($channelPrivacy -eq "Private") {
      $siteUrl = "https://$($M365Domain).sharepoint.com/sites/$($teamPrefix)-$($ProjectNumber)-$($ProjectAbbreviation)-$($teamSuffix)-$($channel)"
    }

    Write-Host "Connecting to :" $siteUrl -ForegroundColor DarkGray
    Connect-PnPOnline -Url $siteUrl -Interactive
    Resolve-PnPFolder -SiteRelativePath "Shared Documents/$folderRelativePath"
  }
}

$scriptEnd = Get-Date
$timeElapsed = New-TimeSpan -Start $scriptStart -End $scriptEnd

Write-Host
Write-Host "Started:`t" $scriptStart -ForegroundColor DarkGray
Write-Host "Finished:`t" $scriptEnd -ForegroundColor DarkGray
Write-Host "Duration:`t" $timeElapsed.ToString("hh\:mm\:ss") -ForegroundColor DarkGray
Write-Host