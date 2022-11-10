#
# This script provisions M365 Groups, and Sensitivity Labels from the list of proponent names passed and appends those label to the existing label policy 
#
# Version 0.1
#
### Prerequisites ###  
#
# 1. Assign following roles to user account running this script
#     * Default role group - Compliance Data Administrator, Compliance Administrator, or Security Administrator role group
#     * Custom role group - add either Sensitivity Label Administrator or Organization Configuration roles to this group 
#
# 2. Set the configuration parameters as necessary 
#    $servicePrincipal - the FQDN of the person that is executing the scripts, or has rights to execute the commands
#    $projectId - the project identifier from IDD for the new project e.g. MR-30000597-MEBD-PRJ
#    $groupOwner - the OMTID person responsible for maintaining the group membership
#    $domainName - the domain name of the tenant the labels are being added to
#    $emailToSendNotification - the FQDN of the person that to whom email notification is triggered when DLP policy is matched
#    
### Provisioning Instructions ### 
# 1. Ensure prerequisites are completed
# 2. Browse to the script directory
#     cd "<script_location_in_file_system>"
# 3. Execute LabelAutomation.ps11
#     Syntax: .\ProponentLabelAutomation.ps1 -servicePrincipal "c3652-adm@mainroads.wa.gov.au" -projectId "MR-30000597-MEBD-CON" -groupOwner "scott.white@mainroads.wa.gov.au" -domainName "group.mainroads.wa.gov.au"  -proponentNames "proponent1", "proponent2", "proponent3"
#

param ($servicePrincipal, $projectId, $groupOwner, $domainName, $emailToSendNotification, $proponentNames)

#### Import the Exchange Online Management Module
Write-Host "Connecting to Exchange Online centre"
Import-Module ExchangeOnlineManagement

#### Connect to Exchange Online Remotely
Connect-ExchangeOnline -UserPrincipalName $servicePrincipal

#### Set reusable variables
# prefix for groups / names / etc
$prefix = $projectId

# Group Names
$groupNameSupport = "$prefix Project Support"
$groupNameEvalQualitative = "$prefix Eval Qualitative"
$groupNameEvalCommercial = "$prefix Eval Commercial"
$groupNameProbity = "$prefix Probity"
$groupNameLegal = "$prefix Legal"
$groupNameGovernance = "$prefix Governance"
$groupNameProponents = @()

# Alias
$aliasSupport = $groupNameSupport.replace(" ", "-")
$aliasEvalQualitative = $groupNameEvalQualitative.replace(" ", "-")
$aliasEvalCommercial = $groupNameEvalCommercial.replace(" ", "-")
$aliasProbity = $groupNameProbity.replace(" ", "-")
$aliasGovernance = $groupNameGovernance.replace(" ", "-")
$aliasLegal = $groupNameLegal.Replace(" ", "-")
$aliasProponents = @()

#### Create M365 Groups
Write-Host "Creating M365 Groups..."

# Create all Proponent groups
foreach ($proponent in $proponentNames) {
    $groupNameProponent = "$prefix $proponent Qualitative"
    $aliasProponent = $groupNameProponent.Replace(" ", "-")

    $groupNameProponents += $groupNameProponent
    $aliasProponents += $aliasProponent

    Write-Host "Creating $groupNameProponent group..."
    New-UnifiedGroup -DisplayName $groupNameProponent -Alias $aliasProponent -AccessType "Private" -Owner $groupOwner
    Set-UnifiedGroup -Identity $aliasProponent -UnifiedGroupWelcomeMessageEnabled:$false
}

#### Connect to Compliance Centre Remotely
Write-Host "Connecting to Compliance centre"
Connect-IPPSSession -UserPrincipalName $servicePrincipal

##### Create Labels

# Label Names - cannot be changed (not the display names of the labels)
$lbNameProponents = @()

# Permissions
$VESPC = "VIEW,VIEWRIGHTSDATA,PRINT,EXTRACT,DOCEDIT,EDIT,EXPORT,OBJMODEL"
$O = "OWNER"

foreach ($proponent in $proponentNames) {
    $lbName = "$prefix-$proponent-Qualitative"
    $lbNameProponents += $lbName
}

### Child Labels
Write-Host "Creating Child labels..."

$count = 0
foreach ($labelName in $lbNameProponents) {
    Write-Host "Creating $labelName label..."
    New-Label -Name $labelName -DisplayName "$($proponentNames[$count]) - Official Sensitive" -Tooltip "This label is to be applied to any $($proponentNames[$count]) documents" -ContentType "File, Email" -EncryptionEnabled $true -EncryptionEncryptOnly $false -EncryptionProtectionType "Template" -EncryptionRightsDefinitions "$($aliasProponents[$count])@$($domainName)`:$($VESPC);$($aliasEvalQualitative)@$($domainName)`:$($VESPC);$($aliasEvalCommercial)@$($domainName)`:$($VESPC);$($aliasProbity)@$($domainName)`:$($VESPC);$($aliasLegal)@$($domainName)`:$($VESPC);$($aliasGovernance)@$($domainName)`:$($VESPC);$($aliasSupport)@$($domainName)`:$($O)" -EncryptionOfflineAccessDays "-1" -ParentId $prefix

    $count++
}

# Update label policy
Write-Host "Updating the label policy"
Set-LabelPolicy -Identity "$prefix Label Policy" -AddLabels $lbNameProponents
Write-Host "Done!"

##### Disconnect from Remote Connection
Disconnect-ExchangeOnline -Confirm:$false
