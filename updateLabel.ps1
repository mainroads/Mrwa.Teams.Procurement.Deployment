#
# This updates the existing security groups, Sensitivity Labels and Label Policy
# Version 0.2
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
#    
### Provisioning Instructions ### 
# 1. Ensure prerequisites are completed
# 2. Browse to the script directory
#     cd "<script_location_in_file_system>"
# 3. Execute LabelAutomation.ps11
#     Syntax: .\LabelAutomation.ps1 -servicePrincipal “c3652-adm@mainroads.wa.gov.au” -projectId “MR-30000597-MEBD-CON” -groupOwner “scott.white@mainroads.wa.gov.au” -domainName “group.mainroads.wa.gov.au” 
#
param ($servicePrincipal,$projectId,$groupOwner,$domainName)

#### Import the Exchange Online Management Module
Import-Module ExchangeOnlineManagement

#### Connect to Exchange Online Remotely
Connect-ExchangeOnline -UserPrincipalName $servicePrincipal

#### Set reusable variables
# prefix for groups / names / etc
$prefix = $projectId

# Group Names
$groupNameManagement = "$prefix Project Management"
$groupNameSupport = "$prefix Project Support"
$groupNameEvalQualitative = "$prefix Eval Qualitative"
$groupNameEvalCommercial = "$prefix Eval Commercial"
$groupNameProbity = "$prefix Probity"
$groupNameGovernance = "$prefix Governance"
$groupNameContractor = "$prefix Contractor"

# Alias
$aliasManagement = $groupNameManagement.replace(" ", "-")
$aliasSupport = $groupNameSupport.replace(" ", "-")
$aliasEvalQualitative = $groupNameEvalQualitative.replace(" ", "-")
$aliasEvalCommercial = $groupNameEvalCommercial.replace(" ", "-")
$aliasProbity = $groupNameProbity.replace(" ", "-")
$aliasGovernance = $groupNameGovernance.replace(" ", "-")
$aliasContractor = $groupNameContractor.replace(" ", "-")

# Create new M365 group

# Update Applicant/Proponent to Contractor
Set-UnifiedGroup -Identity "$prefix-Applicant/Proponent" -Alias $aliasContractor -DisplayName $groupNameContractor -PrimarySmtpAddress "$aliasContractor@$domainName"

#### Connect to Compliance Centre Remotely
Connect-IPPSSession -UserPrincipalName $servicePrincipal

# Label Names - cannot be changed (not the display names of the labels)
$lbNameTender = "$prefix-Tender"
$lbNameSubmission = "$prefix-Submission"
$lbNameEvalQualitative = "$prefix-Evaluation-Qualitative"
$lbNameEvalCommercial = "$prefix-Evaluation-Commercial"
$lbNameStrictlyConfidential = "$prefix-Strictly-Confidential"
$lbNameContractAward = "$prefix-Contract-Award"
$lbNameForRelease = "$prefix-For-Release"

### Creating new label
# Evaluation Qualitative
New-Label -Name $lbNameEvalQualitative -DisplayName "Evaluation Qualitative - Official Sensitive" -Tooltip "This label is to be applied to any evaluation qualitative documentation" -ContentType "File, Email" -EncryptionEnabled $true -EncryptionEncryptOnly $false -EncryptionProtectionType "Template" -EncryptionRightsDefinitions "$aliasSupport@$domainName`:OWNER;$aliasEvalQualitative@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$aliasEvalCommercial@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$aliasProbity@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$aliasGovernance@$domainName`:VIEW,VIEWRIGHTSDATA,PRINT,DOCEDIT,EDIT,OBJMODEL" -EncryptionOfflineAccessDays "-1" -ParentId $prefix

# Evaluation Commercial
New-Label -Name $lbNameEvalCommercial -DisplayName "Evaluation Commercial - Official Sensitive" -Tooltip "This label is to be applied to any evaluation commercial documentation" -ContentType "File, Email" -EncryptionEnabled $true -EncryptionEncryptOnly $false -EncryptionProtectionType "Template" -EncryptionRightsDefinitions "$aliasSupport@$domainName`:OWNER;$aliasEvalCommercial@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$aliasProbity@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$aliasGovernance@$domainName`:VIEW,VIEWRIGHTSDATA,PRINT,DOCEDIT,EDIT,OBJMODEL" -EncryptionOfflineAccessDays "-1" -ParentId $prefix


### Updating the existing labels
### Updating labels to include permission to Governence and Probity
# Contract Award
Set-Label -Identity $lbNameContractAward -EncryptionRightsDefinitions "$aliasManagement@$domainName`:VIEW,VIEWRIGHTSDATA,OBJMODEL;$aliasSupport@$domainName`:OWNER;$aliasEvalQualitative@$domainName`:VIEW,VIEWRIGHTSDATA,OBJMODEL;$aliasEvalCommercial@$domainName`:VIEW,VIEWRIGHTSDATA,OBJMODEL;$aliasProbity@$domainName`:VIEW,VIEWRIGHTSDATA,OBJMODEL;$aliasGovernance@$domainName`: VIEW,VIEWRIGHTSDATA,OBJMODEL;$aliasContractor@$domainName`: VIEW,VIEWRIGHTSDATA,PRINT,EXTRACT,DOCEDIT,EDIT,EXPORT,OBJMODEL"

# Tender
Set-Label -Identity $lbNameTender -EncryptionRightsDefinitions "$aliasManagement@$domainName`:VIEW,VIEWRIGHTSDATA,PRINT,EXTRACT,DOCEDIT,EDIT,EXPORT,OBJMODEL;$aliasSupport@$domainName`:OWNER;$aliasEvalQualitative@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$aliasEvalCommercial@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$aliasProbity@$domainName`:VIEW,VIEWRIGHTSDATA,PRINT,EXTRACT,DOCEDIT,EDIT,EXPORT,OBJMODEL;$aliasGovernance@$domainName`:VIEW,VIEWRIGHTSDATA,PRINT,EXTRACT,DOCEDIT,EDIT,EXPORT,OBJMODEL"

# Submission
Set-Label -Identity $lbNameSubmission -EncryptionRightsDefinitions "$aliasSupport@$domainName`:OWNER;$aliasEvalQualitative@$domainName`:VIEW,VIEWRIGHTSDATA,OBJMODEL;$aliasEvalCommercial@$domainName`:VIEW,VIEWRIGHTSDATA,OBJMODEL;$aliasProbity@$domainName`:VIEW,VIEWRIGHTSDATA,OBJMODEL;$aliasGovernance@$domainName`:VIEW,VIEWRIGHTSDATA,OBJMODEL"

# Strictly Confidential
Set-Label -Identity $lbNameStrictlyConfidential -EncryptionRightsDefinitions "$aliasManagement@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$aliasSupport@$domainName`:OWNER;$aliasEvalQualitative@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$aliasEvalCommercial@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$aliasProbity@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$aliasGovernance@$domainName`: VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL"

# Contract Award
Set-Label -Identity $lbNameContractAward -EncryptionRightsDefinitions "$aliasManagement@$domainName`:VIEW,VIEWRIGHTSDATA,OBJMODEL;$aliasSupport@$domainName`:OWNER;$aliasEvalQualitative@$domainName`:VIEW,VIEWRIGHTSDATA,OBJMODEL;$aliasEvalCommercial@$domainName`:VIEW,VIEWRIGHTSDATA,OBJMODEL;$aliasProbity@$domainName`:VIEW,VIEWRIGHTSDATA,OBJMODEL;$aliasGovernance@$domainName`: VIEW,VIEWRIGHTSDATA,OBJMODEL;$aliasContractor@$domainName`: VIEW,VIEWRIGHTSDATA,PRINT,EXTRACT,DOCEDIT,EDIT,EXPORT,OBJMODEL"

# Update label policy
Set-LabelPolicy -Identity "$prefix Label Policy" -AddLabels $lbNameEvalQualitative, $lbNameEvalCommercial -RemoveLabels "$prefix-Evaluation"

# Remove Evaluation label
Remove-Label -Identity "$prefix-Evaluation" -Confirm:$false

##### Disconnect from Remote Connection
Disconnect-ExchangeOnline -Confirm:$false