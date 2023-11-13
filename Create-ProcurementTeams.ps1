#
# This script provisions IDD project and contract Teams for Procurement team 
# Version 0.6.1
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
$foldersCsvFileRelativePath = Join-Path -Path "Seed" -ChildPath "$($teamType)_Team_Folder_Structure.csv"
$tenant = "$($M365Domain).onmicrosoft.com"

#/Teams (teams) or /Sites (sites)
$spUrlType = "teams" 

$currentDate = get-date -Format "yyyyMMdd_hhmm"
$logsFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "Logs"
if (-not (Test-Path -Path $logsFolderPath)) {
    New-Item -ItemType Directory -Force -Path $logsFolderPath
}
$logFile = Join-Path -Path $logsFolderPath -ChildPath "$currentDate-CreateProcurementTeams.log"

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

Function AppendLog {
    Param(
        [Parameter(Mandatory = $true)]
        [string] $message,

        [Parameter(Mandatory = $false)]
        [System.ConsoleColor] $ForegroundColor = [System.ConsoleColor]::Yellow
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logMessage = "$timestamp $message"
    
    Write-Host $logMessage -ForegroundColor $ForegroundColor
}

#---------------------------------
# CleanUpParameters Function
#---------------------------------
Function CleanUpParameters() {   
    # Removes start and ending spaces in parameters, replaces all other spaces with dashes
    AppendLog " - Checking parameters for white spaces..." -ForegroundColor Yellow

    foreach ($parameter in $parametersTable.GetEnumerator()) {
        if ($parameter.Key -eq "Subsites" -and $subsites) {
            $parameterTrim = $parameter.Value.ToString().Trim();
            $parameter.Value = $parameterTrim
            $newParam = $parameter.Value.replace(" ", "");
            $parameters.Add($parameter.Key, $newParam); 
        } 
        else {
            $parameterTrim = $parameter.Value.ToString().Trim();
            $parameter.Value = $parameterTrim
            if ($parameter.Key -ne "ProjectName") {
                $newParameter = $parameter.Value.replace(" ", "-");
            }
            else {
                $newParameter = $parameter.Value
            }
            $parameters.Add($parameter.Key, $newParameter); 
        }
    }

    foreach ($parameter in $parameters.GetEnumerator()) {
        #AppendLog "   - New parameter: " $parameter.Key $parameter.Value

        if ($parameter.Key -eq "TeamPrefix") {
            $global:prefix = $parameter.Value; 
        }
        if ($parameter.Key -eq "TeamSuffix") {
            $global:suffix = $parameter.Value;
        }
        if ($parameter.Key -eq "ProjectNumber") {
            $global:prjNumber = $parameter.Value;
        }
        if ($parameter.Key -eq "ProjectAbbreviation") {
            $global:prjAbbreviation = $parameter.Value;
        }
        if ($parameter.Key -eq "ProjectName") {
            $global:prjName = $parameter.Value;
        }
        if ($parameter.Key -eq "Subsites") {
            $sites = $parameter.Value.Split(",");
            $global:sites = $sites;
        }

        $global:siteUrl = "https://$($M365Domain).sharepoint.com/$spUrlType/$($global:prefix)-$($global:prjNumber)-$($global:prjAbbreviation)-$($global:suffix)";
    }
}

function GetPrivateChannels {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $csv = Import-Csv -Path $Path
    $uniqueEntries = New-Object System.Collections.Generic.HashSet[string]

    foreach ($row in $csv) {
        if ($row.Privacy -eq 'Private') {
            $parts = $row.Folder -split '/'
            if ($parts.Length -gt 0) {
                [void]$uniqueEntries.Add($global:siteUrl + "-" + $parts[0])
            }
        }
    }

    return [System.Linq.Enumerable]::ToArray($uniqueEntries)
}

#---------------------------------
# ConnectToSharePoint Function
#---------------------------------
Function ConnectToSharePoint() {  
    # Connect to SharePoint:
    AppendLog " - Connecting to SharePoint..." -ForegroundColor Yellow

    Connect-PnPOnline -Url $adminUrl -Interactive

    $pnpPowerShellApp = Get-PnPAzureADApp -Identity $pnpPowerShellAppName -ErrorAction SilentlyContinue

    if ($null -eq $pnpPowerShellApp) {

        $graphPermissions = "Group.Read.All", "Group.ReadWrite.All", "Directory.Read.All",
        "Directory.ReadWrite.All", "Channel.ReadBasic.All", "ChannelSettings.Read.All",
        "ChannelSettings.ReadWrite.All", "Channel.Create", "Team.ReadBasic.All", "TeamSettings.Read.All",
        "TeamSettings.ReadWrite.All", "User.ReadWrite.All", "Group.Read.All"

        $sharePointApplicationPermissions = "Sites.FullControl.All", "User.ReadWrite.All"

        $sharePointDelegatePermissions = "AllSites.FullControl"

        Register-PnPAzureADApp -ApplicationName $pnpPowerShellAppName -Tenant $tenant -OutPath E:\Temp -DeviceLogin -GraphApplicationPermissions $graphPermissions -SharePointApplicationPermissions $sharePointApplicationPermissions
    }
}

#---------------------------------
# CreateTeamAndSites Function
#---------------------------------
Function CreateTeamsAndSites() {
    # Invoke template to create Team, Channels
    AppendLog " - Creating Teams and Sites..." -ForegroundColor Yellow

    $stopInvokingTemplate = $false
    $retryCount = 0
    $maxRetryCount = 3 

    do {
        try {
      
            if ($teamType -eq "Project") {
                Invoke-PnPTenantTemplate -Path (Join-Path -Path "Templates" -ChildPath "Project_Team.xml") -Parameters $parameters
            }
            elseif ($teamType -eq "Contract") {
                Invoke-PnPTenantTemplate -Path (Join-Path -Path "Templates" -ChildPath "Contract_Team.xml") -Parameters $parameters
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
                AppendLog "   - Something went wrong....retry attempt : $retryCount"
            }
        }
    }
    While ($stopInvokingTemplate -eq $false)

    ######### Wait up to 3 minutes to teams provisioning to complete 100% #######################

    $timeoutSeconds = 180
    $intervalSeconds = 15
    $notProvisionedSites = @()
    
    $channelSites = GetPrivateChannels -Path $foldersCsvFileRelativePath
    foreach ($channelSite in $channelSites) {
        $siteUrl = UpdateSiteUrl -siteUrl $channelSite
        $siteProvisioned = $false
        $counter = 0
    
        while (-not $siteProvisioned -and $counter * $intervalSeconds -lt $timeoutSeconds) {
            $percent = $counter * $intervalSeconds * 100 / $timeoutSeconds; 
    
            Write-Progress -Activity "Waiting for the $siteUrl to be provisioned" -Status "$($timeoutSeconds - $counter * $intervalSeconds) seconds remaining..." -PercentComplete $percent; 
    
            Connect-PnPOnline -Url $siteUrl -Interactive
            $objSite = Get-PnPWeb -ErrorAction SilentlyContinue
    
            if ($null -ne $objSite) {
                $siteProvisioned = $true
                AppendLog "Site $siteUrl has been provisioned."
            }
            else {
                Start-Sleep -Seconds $intervalSeconds
                $counter++
            }
        }
    
        if (-not $siteProvisioned) {
            $notProvisionedSites += $siteUrl
        }
    }
    
    if ($notProvisionedSites.Count -gt 0) {
        AppendLog "The following sites were not provisioned within the expected time:" -ForegroundColor Red
        foreach ($site in $notProvisionedSites) {
            AppendLog $site
        }
        exit
    }
    
    
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "ApplyDocumentsLibraryConfigForReviewFlow.ps1"
    & $scriptPath -TargetSiteURL $global:siteUrl

}

#---------------------------------
# CreateTeamsChannels Function
#---------------------------------
Function CreateTeamsChannels() {
    # Code to invoke private channel sites
    AppendLog " - Creating Teams channels..." -ForegroundColor Yellow

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
                    Invoke-RestMethod -Headers @{Authorization = "Bearer $accessToken" } -Uri "https://graph.microsoft.com/beta/teams/$($team.id)/channels/$($channel.id)/filesFolder" | Out-Null
                    $stopLoop = $true
                }
                catch {
                    if ($retryCount -gt $maxRetryCount) {
                        $stoploop = $true
                    }
                    else {
                        Start-Sleep -Seconds 30
                        $retryCount = $retryCount + 1
                        $retrymsg = "Channel " + $channel + "attempt " + $retryCount.ToString()
                        AppendLog $retrymsg -ForegroundColor DarkYellow
                    }
                }
            }
            While ($stopLoop -eq $false)
        }

        $channelSites = GetPrivateChannels -Path $foldersCsvFileRelativePath
        foreach ($channelSite in $channelSites) {
            $siteUrl = UpdateSiteUrl -siteUrl $channelSite
            Connect-PnPOnline -Url $siteUrl -Interactive
            UpdateSiteSettings -siteUrl $siteUrl
            $isReviewModeFieldPresent = Get-PnPField -List "Documents" -Identity "ReviewMode" -ErrorAction SilentlyContinue
            if ($null -eq $isReviewModeFieldPresent) {
                $TemplateFilePath = Join-Path -Path $PSScriptRoot -ChildPath (Join-Path -Path "Templates" -ChildPath "DocumentLibraryConfigReview.xml")
                & (Join-Path -Path "$PSScriptRoot" -ChildPath "ApplyDocumentsLibraryConfigForReviewFlow.ps1") -TargetSiteURL $siteUrl -TemplateFilePath $TemplateFilePath
            }
        }
    }
    catch {
        AppendLog $_
    }
}

#---------------------------------
# CreateSubsiteFolderStructures Function
#---------------------------------
Function CreateSubsiteFolderStructures() { 
    if ($global:sites) {
        AppendLog " - Creating folder Structures in subsites..." -ForegroundColor Yellow

        foreach ($site in $global:sites) {
            $siteUrl = ""

            AppendLog "   - Subsite: $site" 
            foreach ($folder in (import-csv $foldersCsvFileRelativePath)) { 
                $folderPrivacy = $folder.Privacy
                if ($folderPrivacy -eq "Subsite") {  
                    $folderRelativePath = ($folder.Folder).Replace('XXX', $global:prjAbbreviation).Replace('$ProjectNumber', $global:prjNumber)
                    $subSite = $folderRelativePath.Substring(0, $folderRelativePath.IndexOf("/"))

                    # AppendLog "site: $($site), subSite: $($subsite)" 
                    if ($site -eq $subSite) {
                        $folderContractType = $folder.ContractType

                        $siteUrl = "https://$($M365Domain).sharepoint.com/$spUrlType/$($global:prefix)-$($global:prjNumber)-$($global:prjAbbreviation)-$($global:suffix)/$($site)"

                        $subFolderRelPath = $folderRelativePath.Substring($subSite.Length + 1, $folderRelativePath.Length - $subSite.Length - 1)
                        AppendLog "   - Processing: $($siteUrl)/Shared Documents/$subFolderRelPath" 
                        Connect-PNPonline -Url $siteUrl -Interactive

                        if (($folderContractType -eq $contractType) -or ($folderContractType -eq "Common")) {
                            Resolve-PnPFolder -SiteRelativePath "Shared Documents/$subFolderRelPath" | Out-Null
                        }
                    }
                }
            }
            
        }               
    }               
}

function UpdateSiteUrl {
    param(
        [Parameter(Mandatory = $true)]
        [string]$siteUrl
    )
    
    Connect-PnPOnline -Url $siteUrl -Interactive
    $objSite = Get-PnPWeb -ErrorAction SilentlyContinue
  
    if ($null -eq $objSite) {
        if ($siteUrl -match "/teams/") {
            # Write-Warning "Was expecting $siteUrl now retrying with /sites/"
            $siteUrl = $siteUrl -replace "/teams/", "/sites/"
        }
        else {
            # Write-Warning "Was expecting $siteUrl now retrying with /teams/"
            $siteUrl = $siteUrl -replace "/sites/", "/teams/"                     
        }
    }

    return $siteUrl
}


#---------------------------------
# CreateFolderStructures Function
#---------------------------------
Function CreateFolderStructures() {
    # PnP Provisioning Schema currently does not have support for adding folders 
    # to private channels. Therefore, add folders explicitly using the following 
    # logic. Use this consistently to add folders for both standard and private
    # channels. This logic is not required when provisioning schema is updated 
    # in the later versions to add folders to private channels
    if (!$NoFolderCreation) {
        AppendLog " - Creating Folder Structures in Channels..." -ForegroundColor Yellow 

        foreach ($folder in (import-csv $foldersCsvFileRelativePath)) {
            $channelPrivacy = $folder.Privacy
            $folderRelativePath = ($folder.Folder).Replace('XXX', $global:prjAbbreviation).Replace('ProjectNumber', $global:prjNumber)
            $folderContractType = $folder.ContractType 

            if ($channelPrivacy -eq "Standard") {
                $siteUrl = "https://$($M365Domain).sharepoint.com/$spUrlType/$($global:prefix)-$($global:prjNumber)-$($global:prjAbbreviation)-$($global:suffix)"
            }
            elseif ($channelPrivacy -eq "Private") {
                $channel = $folderRelativePath.Substring(0, $folderRelativePath.IndexOf("/"))
                $siteUrl = UpdateSiteUrl -siteUrl "https://$($M365Domain).sharepoint.com/$spUrlType/$($global:prefix)-$($global:prjNumber)-$($global:prjAbbreviation)-$($global:suffix)-$($channel)"
            }

            Connect-PnPOnline -Url $siteUrl -Interactive

            if ($channelPrivacy -ne "Subsite" -and ($folderContractType -eq $contractType -or $folderContractType -eq "Common")) {
                AppendLog "   - Processing: $folderRelativePath..." 
                Resolve-PnPFolder -SiteRelativePath "Shared Documents/$folderRelativePath" | Out-Null
            }
        }
    }
}

#---------------------------------
# UpdateSiteSettings Function
#---------------------------------
Function UpdateSiteSettings {    
    param(
        [Parameter(Mandatory=$true)]
        [string]$siteUrl
    )
    AppendLog " - Updating Site Settings" -ForegroundColor Yellow
    
    Connect-PnPOnline -Url $siteUrl -Interactive
    Set-PnPList -Identity "Documents" -OpenDocumentsMode "ClientApplication"
    
    $web = Get-PnPWeb -Includes RegionalSettings, RegionalSettings.TimeZones
    $timeZone = $web.RegionalSettings.TimeZones | Where-Object { $_.Id -eq 73 } # Perth
    $web.RegionalSettings.LocaleId = 3081 # English(Australia)
    $web.RegionalSettings.TimeZone = $timeZone 
    $web.Update()
    Invoke-PnPQuery
}

#-------------------------------------------
# CreateNewGroupAndPermissionLevel Function
#-------------------------------------------
Function CreateNewGroupAndPermissionLevel() {
    AppendLog "   - Creating 'Contribute without Delete' Permission Level for SP site..." -ForegroundColor Yellow     

    Connect-PnPOnline -Url $global:siteUrl -Interactive  

    #Get Permission level to copy
    $contributeRole = Get-PnPRoleDefinition -Identity "Contribute"

    #Check if 'Contribute without delete' already exists
    $customRole = Get-PnPRoleDefinition -Identity "Contribute without delete" -ErrorAction SilentlyContinue

    if ($null -eq $customRole) {
        #Create a custom Permission level and exclude delete from contribute
        Add-PnPRoleDefinition -RoleName "Contribute without delete" -Clone $contributeRole -Exclude DeleteListItems, DeleteVersions -Description "Contribute without delete permission" | Out-Null
        $PermissionGroupName = "$($global:prefix)-$($global:prjNumber)-$($global:prjAbbreviation)-$($global:suffix)" + " " + "Contributors"
        New-PnPSiteGroup -Site $siteUrl -Name $PermissionGroupName -PermissionLevels "Contribute without delete" | Out-Null
    }
    else {
        AppendLog "   - Permission Level 'Contribute without delete' already exists." -ForegroundColor Yellow
    }
}

#---------------------------------
# CreateSubsites Function
#---------------------------------
Function CreateSubsites() {
    if ($global:sites) {
        AppendLog " - Creating Subsites..." -ForegroundColor Yellow 
 
        foreach ($site in $global:sites) { 
 
            $subsiteUrl = $global:siteUrl + "/" + $site
            Connect-PnPOnline -Url $subsiteUrl -Interactive 
            $objSubsite = Get-PnPWeb -ErrorAction SilentlyContinue

            if ($null -eq $objSubsite) { 
                AppendLog " - Creating subsite: $site"
                Connect-PnPOnline -Url $global:siteUrl -Interactive 
                New-PnPWeb -Title (Get-Culture).TextInfo.ToTitleCase($site) -Url $site -Template "STS#3" -BreakInheritance | Out-Null

                # Stops the script from erroring out, gets deactivated later
                Enable-PnPFeature -Identity 8a4b8de2-6fd8-41e9-923c-c7c3c00f8295 -Scope Site 
                Invoke-PnPQuery

                Add-PnPNavigationNode -Title (Get-Culture).TextInfo.ToTitleCase($site) -Location "TopNavigationBar" -Url $site
 
                $TemplateFilePath = Join-Path -Path $PSScriptRoot -ChildPath (Join-Path -Path "Templates" -ChildPath "DocumentLibraryConfigReview_SubSite.xml")
                $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "ApplyDocumentsLibraryConfigForReviewFlow.ps1"
                & $scriptPath -TargetSiteURL $subsiteUrl -TemplateFilePath $TemplateFilePath
           

                $PermissionGroupNameMembers = "$($global:prefix)-$($global:prjNumber)-$($global:prjAbbreviation)-$($global:suffix)" + " " + $site + " " + "Members"
                New-PnPGroup -Title (Get-Culture).TextInfo.ToTitleCase($PermissionGroupNameMembers) 

                $PermissionGroupNameVisitors = "$($global:prefix)-$($global:prjNumber)-$($global:prjAbbreviation)-$($global:suffix)" + " " + $site + " " + "Visitors"
                New-PnPGroup -Title (Get-Culture).TextInfo.ToTitleCase($PermissionGroupNameVisitors) 

                $PermissionGroupNameOwners = "$($global:prefix)-$($global:prjNumber)-$($global:prjAbbreviation)-$($global:suffix)" + " " + $site + " " + "Owners"
                New-PnPGroup -Title (Get-Culture).TextInfo.ToTitleCase($PermissionGroupNameOwners) 

                $PermissionGroupContributors = "$($global:prefix)-$($global:prjNumber)-$($global:prjAbbreviation)-$($global:suffix)" + " " + $site + " " + "Contributors"
                New-PnPGroup -Title (Get-Culture).TextInfo.ToTitleCase($PermissionGroupContributors) 

                Connect-PnPOnline -Url $subsiteUrl -Interactive 
                Set-PnPGroup -Identity $PermissionGroupNameMembers -AddRole "Edit"
                Set-PnPGroup -Identity $PermissionGroupNameVisitors -AddRole "Read"
                Set-PnPGroup -Identity $PermissionGroupNameOwners -AddRole "Full Control"
                Set-PnPGroup -Identity $PermissionGroupContributors -AddRole "Contribute without delete"
            }
            else {
                AppendLog " - Subsite $site already exists. Skipping creation." -ForegroundColor Yellow
            }
        }
    }
    else {
        AppendLog "Subsite parameter not selected."
    }
}


#----------------------------------------
# UpdateSubsiteSettings Function
#----------------------------------------
Function UpdateSubsiteSettings() {
    if ($global:sites) {
        AppendLog " - Updating Subsites Settings..." -ForegroundColor Yellow     

        Connect-PnPOnline -Url $global:siteUrl -Interactive  
        $subSites = Get-PnPSubWeb -Recurse
        
        foreach ($site in $subSites) {    
            Connect-PNPonline -Url "$($site.Url)" -Interactive
           
            Set-PnPList -Identity "Documents" -OpenDocumentsMode "ClientApplication"

            $web = Get-PnPWeb -Includes RegionalSettings, RegionalSettings.TimeZones 
            $timeZone = $web.RegionalSettings.TimeZones | Where-Object { $_.Id -eq 73 } # Perth
            $web.RegionalSettings.LocaleId = 3081 # English(Australia)
            $web.RegionalSettings.TimeZone = $timeZone 
            Disable-PnPFeature -Identity 41e1d4bf-b1a2-47f7-ab80-d5d6cbba3092
            $web.Update()
            Invoke-PnPQuery
        }
    }
    else {
        AppendLog "Subsite parameter not selected."
    }
}

#---------------------------------
# Main Function
#---------------------------------
Function Main() {
    AppendLog "`Teams Procurement script has started `n" -ForegroundColor Green

    $scriptStart = Get-Date

    # Call CleanUpParameters function
    # Never comment out this function, it is needed for the other functions to work
    CleanUpParameters

    # Call ConnectToSharePoint function
    ConnectToSharePoint

    # Call CreateTeamAndSites function
    CreateTeamsAndSites # First Attempt
    CreateTeamsAndSites # Second Attempt to ensure all channels are provisioned

    # Call CreateTeamsChannels function
    CreateTeamsChannels

    # Call CreateNewGroupAndPermissionLevel
    CreateNewGroupAndPermissionLevel

    # Call UpdateSiteSettings function
    UpdateSiteSettings -siteUrl $global:siteUrl

    # Call CreateSubsites function
    CreateSubsites

    # Call UpdateSubsiteSettings function
    UpdateSubsiteSettings

    # Call CreateFolderStructures function
    CreateFolderStructures

    # Call CreateSubsiteFolderStructures function
    CreateSubsiteFolderStructures

    $scriptEnd = Get-Date
    $timeElapsed = New-TimeSpan -Start $scriptStart -End $scriptEnd

    AppendLog "`Teams Procurement script has completed. `n" -ForegroundColor Green
    
    Write-Host "`SharePoint Site:`t" $global:siteUrl
    Write-Host "`Started:`t" $scriptStart -ForegroundColor DarkGray
    Write-Host "Finished:`t" $scriptEnd -ForegroundColor DarkGray
    Write-Host "Duration:`t" $timeElapsed.ToString("hh\:mm\:ss") -ForegroundColor DarkGray
}

# Call Main Function
Start-Transcript -Path $logFile
Main
Stop-Transcript