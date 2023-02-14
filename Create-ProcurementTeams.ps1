#
# This script provisions IDD project and contract Teams for Procurement team 
# Version 0.4.2
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
#           * UserPrincipalName for Team Owners in Project_Team.xml, Contract_Team.xml 
#           * Project_Team_Folder_Structure.csv
#           * Contract_Team_Folder_Structure.csv
#
### Provisioning Instructions ### 
# 1. Ensure prerequisites are completed
# 2. Browse to the project directory
#     cd "<project_location_in_file_system>\.Mrwa.Teams.Procurement.Deployment"
# 3. Execute Create-ProcurementTeams.ps1
#     Syntax: .\Create-ProcurementTeams.ps1 -M365Domain <domain_name> -projectName <project_name> -projectNumber <project_number> -projectAbbreviation <project_abbreviation> -contractType <contract_type> -teamType <team_Type> -subsites <subsites> [-NoFolderCreation] 
#
### Provisioning Procedure ###

# Step : Run the below command to start the script which will auto provision the team and channels including folders by default  (Team and channels including subfolders)
# Incase the folders are not required to be provisioned then just use the flag [-NoFolderCreation] which will skip the folder creation steps.
# 
# Note:
#   1. In case script fails while running, just run the command again with the same command to continue the provisioning process 

Param(
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string] $M365Domain,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string] $projectName,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string] $projectNumber,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string] $projectAbbreviation,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [ValidateSet("Alliance", "D&C", IgnoreCase = $true)]
  [string] $contractType,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [ValidateSet("Project", "Contract", IgnoreCase = $true)]
  [string] $teamType,

  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [string] $subsites,

  [switch] $NoFolderCreation = $false
)

$ErrorActionPreference = "Stop"


#--------------------
# Install Dependencies if not already present in current workspace
#--------------------

Get-PackageProvider -Name Nuget -ForceBootstrap
Import-Module PnP.PowerShell -Scope Local -DisableNameChecking

$pnpPowerShellAppName = "PnP Management Shell"

#--------------------
# Configuration
#--------------------

$adminUrl = "https://$($M365Domain)-admin.sharepoint.com/"
$global:teamPrefix = "MR"
$global:teamSuffix = if ($teamType -eq "Project") { "PRJ" } else { "CON" }
$foldersCsvFileRelativePath = "Seed\$($teamType)_Team_Folder_Structure.csv"
$tenant = "mainroads.onmicrosoft.com"



#/Teams (teams) or /Sites (sites)
$spUrlType = "teams" 

$currentDate = get-date -Format "yyyyMMdd_hhmm"
$logFile = "$PSScriptRoot\$currentDate-CreateProcurementTeams.log"

$parametersTable = @{
  "TeamPrefix"          = $teamPrefix
  "TeamSuffix"          = $teamSuffix
  "ProjectNumber"       = $projectNumber
  "ProjectAbbreviation" = $projectAbbreviation
  "ProjectName"         = $projectName
  "Subsites"            = $subsites
}

$parameters = @{}

$global:prefix = $null;
$global:suffix = $null;
$global:prjNumber = $null;
$global:prjAbbreviation;
$global:prjName = $null;
$global:sites = $null;
$global:siteUrl = $null;

#---------------------------------
# CleanUpParameters Function
#---------------------------------
Function CleanUpParameters()
{   
    # Removes start and ending spaces in parameters, replaces all other spaces with dashes
    Write-Host " - Checking parameters for white spaces..." -ForegroundColor Yellow

    foreach ($parameter in $parametersTable.GetEnumerator())
    {
        if($parameter.Key -eq "Subsites" -and $subsites)
        {
            $parameterTrim = $parameter.Value.ToString().Trim();
            $parameter.Value = $parameterTrim
            $newParam = $parameter.Value.replace(" ","");
            $parameters.Add($parameter.Key, $newParam); 
        } 
        else 
        {
            $parameterTrim = $parameter.Value.ToString().Trim();
            $parameter.Value = $parameterTrim
            $newParameter = $parameter.Value.replace(" ","-");
            $parameters.Add($parameter.Key, $newParameter); 
        }
    }

    foreach ($parameter in $parameters.GetEnumerator())
    {
        #Write-Host "   - New parameter: " $parameter.Key $parameter.Value

        if($parameter.Key -eq "TeamPrefix")
        {
            $global:prefix = $parameter.Value; 
        }
        if($parameter.Key -eq "TeamSuffix")
        {
            $global:suffix = $parameter.Value;
        }
        if($parameter.Key -eq "ProjectNumber")
        {
            $global:prjNumber = $parameter.Value;
        }
        if($parameter.Key -eq "ProjectAbbreviation")
        {
            $global:prjAbbreviation = $parameter.Value;
        }
        if($parameter.Key -eq "ProjectName")
        {
            $global:prjName = $parameter.Value;
        }
        if($parameter.Key -eq "Subsites")
        {
            $sites = $parameter.Value.Split(",");
            $global:sites = $sites;
        }

        $global:siteUrl = "https://$($M365Domain).sharepoint.com/$spUrlType/$($global:prefix)-$($global:prjNumber)-$($global:prjAbbreviation)-$($global:suffix)";
    }
}

#---------------------------------
# ConnectToSharePoint Function
#---------------------------------
Function ConnectToSharePoint()
{  
    # Connect to SharePoint:
    Write-Host " - Connecting to SharePoint..." -ForegroundColor Yellow

    Connect-PnPOnline -Url $adminUrl -Interactive

    $pnpPowerShellApp = Get-PnPAzureADApp -Identity $pnpPowerShellAppName -ErrorAction SilentlyContinue

    if($null -eq $pnpPowerShellApp) {

      $graphPermissions = "Group.Read.All","Group.ReadWrite.All","Directory.Read.All",
      "Directory.ReadWrite.All","Channel.ReadBasic.All","ChannelSettings.Read.All",
      "ChannelSettings.ReadWrite.All","Channel.Create","Team.ReadBasic.All","TeamSettings.Read.All",
      "TeamSettings.ReadWrite.All","User.ReadWrite.All","Group.Read.All"

      $sharePointApplicationPermissions = "Sites.FullControl.All","User.ReadWrite.All"

      $sharePointDelegatePermissions = "AllSites.FullControl"

      Register-PnPAzureADApp -ApplicationName $pnpPowerShellAppName -Tenant $tenant -OutPath E:\Temp -DeviceLogin -GraphApplicationPermissions $graphPermissions -SharePointApplicationPermissions $sharePointApplicationPermissions
    }
}

#---------------------------------
# CreateTeamAndSites Function
#---------------------------------
Function CreateTeamsAndSites()
{
    # Invoke template to create Team, Channels
    Write-Host " - Creating Teams and Sites..." -ForegroundColor Yellow

    $stopInvokingTemplate = $false
    $retryCount = 0
    $maxRetryCount = 3 

    do {
      try {
      
        if ($teamType -eq "Project") {
          Invoke-PnPTenantTemplate -Path "Templates\Project_Team.xml" -Parameters $parameters
        }
        elseif ($teamType -eq "Contract") {
          Invoke-PnPTenantTemplate -Path "Templates\Contract_Team.xml" -Parameters $parameters 
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
              Write-Host "   - Something went wrong....retry attempt : $retryCount"
          }
      }
    }
    While ($stopInvokingTemplate -eq $false)

    ######### Wait for 3 minutes to teams provisioning to complete 100% #######################

    $seconds = 180
    1..$seconds |
    ForEach-Object { 
        $percent = $_ * 100 / $seconds; 

        Write-Progress -Activity "Wait for 3 minutes before ensuring the private channel sharepoint sites provisioning" -Status "$($seconds - $_) seconds remaining..." -PercentComplete $percent; 

        Start-Sleep -Seconds 1
    }

    & $PSScriptRoot\ApplyDocumentsLibraryConfigForReviewFlow.ps1 -TargetSiteURL $global:siteUrl
    #ApplyDocumentLibrarySettingsandConfiguration-ReviewFlow -TargetSiteURL $global:siteUrl
}

#---------------------------------
# CreateTeamsChannels Function
#---------------------------------
Function CreateTeamsChannels()
{
    # Code to invoke private channel sites
    Write-Host " - Creating Teams channels..." -ForegroundColor Yellow

    #Request graph access toeken
    $accessToken = Get-PnPGraphAccessToken

    #Get teams data via the Graph
    $response = Invoke-RestMethod -Headers @{Authorization = "Bearer $accessToken" } -Uri "https://graph.microsoft.com/beta/teams?$filter=startswith(displayName, `'$($teamPrefix)-$($projectNumber)-$($projectAbbreviation)`')" -Method 'GET' -ContentType 'application/json'
 
    #Select the data for each team
    $team = $response.value[0] | Select-Object 'displayName', 'id'
 
    try {

        #Get the channel
        $allChannels = (Invoke-RestMethod -Headers @{Authorization = "Bearer $accessToken" } -Uri "https://graph.microsoft.com/beta/teams/$($team.id)/channels" -Method 'GET' -ContentType 'application/json').value | Select-Object 'displayName', 'id'
    
        #Attempt channel check
        $stopLoop = $false
        $retryCount = 0
        $maxRetryCount = 20   
   
        #Trigger private channel SharePoint Onlinesite creation
        foreach ($channel in $allChannels) {
            do {
                try {
                     Invoke-RestMethod -Headers @{Authorization = "Bearer $accessToken" } -Uri "https://graph.microsoft.com/teams/$($team.id)/channels/$($channel.id)/filesFolder" | Out-Null
                    #Invoke-RestMethod -Headers @{Authorization = "Bearer $accessToken" } -Uri "https://graph.microsoft.com/beta/teams/$($team.id)/channels/$($channel.id)/filesFolder" | Out-Null
                    $stopLoop = $true
                }
                catch {
                    if ($retryCount -gt $maxRetryCount) {
                        $stoploop = $true
                    }
                    else {
                        Start-Sleep -Seconds 30
                        $retryCount = $retryCount + 1
                        $retrymsg="Channel " + $channel + "attempt " +  $retryCount.ToString()
                        Write-Host $retrymsg -ForegroundColor DarkYellow
                    }
                }
            }
            While ($stopLoop -eq $false)
        }
    }
    catch {
        Write-Host $_
    }
}

#---------------------------------
# CreateSubsiteFolderStructures Function
#---------------------------------
Function CreateSubsiteFolderStructures()
{ 
    if($global:sites)
    {
        Write-Host " - Creating folder Structures in subsites..." -ForegroundColor Yellow

        foreach($site in $global:sites)
        {     $siteUrl =""

            Write-Host "   - Subsite: $site" 
            foreach ($folder in (import-csv $foldersCsvFileRelativePath)) 
            { 
                $folderPrivacy = $folder.Privacy
                if ($folderPrivacy -eq "Subsite") 
                {  
                    $folderRelativePath = ($folder.Folder).Replace('XXX', $global:prjAbbreviation).Replace('$ProjectNumber', $global:prjNumber)
                    $subSite = $folderRelativePath.Substring(0,$folderRelativePath.IndexOf("/"))

                    Write-Host "site: $($site), subSite: $($subsite)" 
                    if($site -eq $subSite)
                    {
                        $folderContractType = $folder.ContractType

                        $siteUrl = "https://$($M365Domain).sharepoint.com/$spUrlType/$($global:prefix)-$($global:prjNumber)-$($global:prjAbbreviation)-$($global:suffix)/$($site)"

                        $subFolderRelPath = $folderRelativePath.Substring($subSite.Length+1,$folderRelativePath.Length-$subSite.Length-1)
                        Write-Host "   - Processing: $($siteUrl)/Shared Documents/$subFolderRelPath" 
                        Connect-PNPonline -Url $siteUrl -Interactive

                        if(($folderContractType -eq $contractType) -or ($folderContractType -eq "Common")){
                            Resolve-PnPFolder -SiteRelativePath "Shared Documents/$subFolderRelPath" | Out-Null
                        }
                    }
                }
            }
            
        }               
    }               
}

#---------------------------------
# CreateFolderStructures Function
#---------------------------------
Function CreateFolderStructures()
{
    # PnP Provisioning Schema currently does not have support for adding folders 
    # to private channels. Therefore, add folders explicitly using the following 
    # logic. Use this consistently to add folders for both standard and private
    # channels. This logic is not required when provisioning schema is updated 
    # in the later versions to add folders to private channels
    if (!$NoFolderCreation) 
    {
       Write-Host " - Creating Folder Structures in Channels..." -ForegroundColor Yellow 

  
       foreach ($folder in (import-csv $foldersCsvFileRelativePath)) 
        {
            $channelPrivacy = $folder.Privacy
            $folderRelativePath = ($folder.Folder).Replace('XXX', $global:prjAbbreviation).Replace('ProjectNumber', $global:prjNumber)
            $folderContractType = $folder.ContractType 

            if ($channelPrivacy -eq "Standard") {
                $siteUrl = "https://$($M365Domain).sharepoint.com/$spUrlType/$($global:prefix)-$($global:prjNumber)-$($global:prjAbbreviation)-$($global:suffix)"
            }
            elseif ($channelPrivacy -eq "Private") {
                $channel = $folderRelativePath.Substring(0,$folderRelativePath.IndexOf("/"))
                $siteUrl = "https://$($M365Domain).sharepoint.com/$spUrlType/$($global:prefix)-$($global:prjNumber)-$($global:prjAbbreviation)-$($global:suffix)-$($channel)"
            
                          
                             


                            Connect-PnPOnline -Url $siteUrl -Interactive
                            $isReviewModeFieldPresent=Get-PnPField -List "Documents" -Identity "ReviewMode" -ErrorAction SilentlyContinue
                
                            if($isReviewModeFieldPresent -eq $null)
                            {

                                 ######### Wait for 2 minutes to teams private channel provisioning to complete 100% #######################
                                $seconds = 120
                                1..$seconds |
                                ForEach-Object { 
                                    $percent = $_ * 100 / $seconds; 

                                    Write-Progress -Activity "Wait for 2 minutes before ensuring the private channel sharepoint sites provisioning" -Status "$($seconds - $_) seconds remaining..." -PercentComplete $percent; 

                                    Start-Sleep -Seconds 1
                                }
                               
                                & $PSScriptRoot\ApplyDocumentsLibraryConfigForReviewFlow.ps1 -TargetSiteURL $siteUrl
                            }
                                                 

            }

            Connect-PnPOnline -Url $siteUrl -Interactive

            if(($folderContractType -eq $contractType) -or ($folderContractType -eq "Common"))
            {
                Write-Host "   - Processing: $folderRelativePath..." 
                Resolve-PnPFolder -SiteRelativePath "Shared Documents/$folderRelativePath" | Out-Null
            }
        }
    }
}

#---------------------------------
# UpdateRegionalSettings Function
#---------------------------------
Function UpdateRegionalSettings
{    
    write-host " - Updating Regional Settings" -ForegroundColor Yellow
    
    Connect-PnPOnline -Url $global:siteUrl -Interactive
    
    $web = Get-PnPWeb -Includes RegionalSettings, RegionalSettings.TimeZones
    $timeZone = $web.RegionalSettings.TimeZones | Where-Object {$_.Id -eq 73} # Perth
    $web.RegionalSettings.LocaleId = 3081 # English(Australia)
    $web.RegionalSettings.TimeZone = $timeZone 
    $web.Update()
    Invoke-PnPQuery
}

#-------------------------------------------
# CreateNewGroupAndPermissionLevel Function
#-------------------------------------------
Function CreateNewGroupAndPermissionLevel()
{
    write-host "   - Creating 'Contribute without Delete' Permission Level for SP site..." -ForegroundColor Yellow     
        
    Connect-PnPOnline -Url $global:siteUrl -Interactive  

    #Get Permission level to copy
    $contributeRole = Get-PnPRoleDefinition -Identity "Contribute"
 
    #Create a custom Permission level and exclude delete from contribute
    $PermissionGroupName="$($global:prefix)-$($global:prjNumber)-$($global:prjAbbreviation)-$($global:suffix)" +" " + "Contributors"
    Add-PnPRoleDefinition -RoleName "Contribute without delete" -Clone $contributeRole -Exclude DeleteListItems, DeleteVersions -Description "Contribute without delete permission" | Out-Null
    New-PnPSiteGroup -Site $siteUrl -Name $PermissionGroupName -PermissionLevels "Contribute without delete" | Out-Null
}

#---------------------------------
# CreateSubsites Function
#---------------------------------
Function CreateSubsites()
{
    if($global:sites) 
    {
         write-host " - Creating Subsites..." -ForegroundColor Yellow     
        
         foreach($site in $global:sites)
         {    
            write-host "     - Creating subsite: $site"
            Connect-PnPOnline -Url $global:siteUrl -Interactive  
            New-PnPWeb -Title (Get-Culture).TextInfo.ToTitleCase($site) -Url $site -Template "STS#3" -BreakInheritance | Out-Null
            # Stops the script from erroring out, gets deactivated later
            Enable-PnPFeature -Identity 8a4b8de2-6fd8-41e9-923c-c7c3c00f8295 -Scope Site 
            Invoke-PnPQuery

            #ApplyDocumentLibrarySettingsandConfiguration-ReviewFlow -TargetSiteURL $global:siteUrl
            $subsiteUrl= $global:siteUrl + "/" + $site
            & $PSScriptRoot\ApplyDocumentsLibraryConfigForReviewFlow.ps1 -TargetSiteURL $subsiteUrl


            $PermissionGroupNameMembers="$($global:prefix)-$($global:prjNumber)-$($global:prjAbbreviation)-$($global:suffix)" +" " + $site +" " + "Members"
            New-PnPGroup -Title (Get-Culture).TextInfo.ToTitleCase($PermissionGroupNameMembers)  

            $PermissionGroupNameVisitors="$($global:prefix)-$($global:prjNumber)-$($global:prjAbbreviation)-$($global:suffix)" +" " + $site +" " + "Visitors"
            New-PnPGroup -Title (Get-Culture).TextInfo.ToTitleCase($PermissionGroupNameVisitors)  

            $PermissionGroupNameOwners="$($global:prefix)-$($global:prjNumber)-$($global:prjAbbreviation)-$($global:suffix)" +" " + $site +" " + "Owners"
            New-PnPGroup -Title (Get-Culture).TextInfo.ToTitleCase($PermissionGroupNameOwners)  

            $PermissionGroupContributors="$($global:prefix)-$($global:prjNumber)-$($global:prjAbbreviation)-$($global:suffix)" +" " + $site +" " + "Contributors"
            New-PnPGroup -Title (Get-Culture).TextInfo.ToTitleCase($PermissionGroupContributors)  

            Connect-PnPOnline -Url $subsiteUrl -Interactive  
            Set-PnPGroup -Identity $PermissionGroupNameMembers -AddRole "Edit"
            Set-PnPGroup -Identity $PermissionGroupNameVisitors -AddRole "Read"
            Set-PnPGroup -Identity $PermissionGroupNameOwners -AddRole "Full Control"
            Set-PnPGroup -Identity $PermissionGroupContributors -AddRole "Contribute without delete"


           
         }
    }
    else
    {
         write-host "Subsite parameter not selected."
    }
}

#----------------------------------------
# UpdateSubsiteRegionalSettings Function
#----------------------------------------
Function UpdateSubsitesRegionalSettings()
{
    if($global:sites) 
    {
        write-host " - Updating Subsites Regional Settings..." -ForegroundColor Yellow     

        Connect-PnPOnline -Url $global:siteUrl -Interactive  
        $subSites = Get-PnPSubWeb -Recurse
        
         foreach($site in $subSites)
         {    
            Connect-PNPonline -Url "$($site.Url)" -Interactive
           
            $web = Get-PnPWeb -Includes RegionalSettings, RegionalSettings.TimeZones 
            $timeZone = $web.RegionalSettings.TimeZones | Where-Object {$_.Id -eq 73} # Perth
            $web.RegionalSettings.LocaleId = 3081 # English(Australia)
            $web.RegionalSettings.TimeZone = $timeZone 
            Disable-PnPFeature -Identity 41e1d4bf-b1a2-47f7-ab80-d5d6cbba3092
            $web.Update()
            Invoke-PnPQuery
         }
    }
    else
    {
         write-host "Subsite parameter not selected."
    }
}

#---------------------------------
# Main Function
#---------------------------------
Function Main()
{
    Write-Host "`Teams Procurement script has started `n" -ForegroundColor Green

    $scriptStart = Get-Date

    # Call CleanUpParameters function
    # Never comment out this function, it is needed for the other functions to work
    CleanUpParameters

    # Call ConnectToSharePoint function
    ConnectToSharePoint

    # Call CreateTeamAndSites function
    CreateTeamsAndSites

    # Call CreateTeamsChannels function
    CreateTeamsChannels

    # Call CreateNewGroupAndPermissionLevel
    CreateNewGroupAndPermissionLevel

    # Call UpdateRegionalSettings function
    UpdateRegionalSettings

    # Call CreateSubsites function
    CreateSubsites

    # Call UpdateSubsiteRegionalSettings function
    UpdateSubsitesRegionalSettings

    # Call CreateFolderStructures function
    CreateFolderStructures

    # Call CreateSubsiteFolderStructures function
    CreateSubsiteFolderStructures

    $scriptEnd = Get-Date
    $timeElapsed = New-TimeSpan -Start $scriptStart -End $scriptEnd

    Write-Host "`Teams Procurement script has completed. `n" -ForegroundColor Green

    Write-Host
    Write-Host "`SharePoint Site:`t" $global:siteUrl
    Write-Host "`Started:`t" $scriptStart -ForegroundColor DarkGray
    Write-Host "Finished:`t" $scriptEnd -ForegroundColor DarkGray
    Write-Host "Duration:`t" $timeElapsed.ToString("hh\:mm\:ss") -ForegroundColor DarkGray
}

# Call Main Function
Start-Transcript -Path $logFile
Main
Stop-Transcript