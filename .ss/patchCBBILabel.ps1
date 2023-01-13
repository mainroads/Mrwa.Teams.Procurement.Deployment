#
# This updates existing Sensitivity Labels and Label Policy
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
#    
### Provisioning Instructions ### 
# 1. Ensure prerequisites are completed
# 2. Browse to the script directory
#     cd "<script_location_in_file_system>"
# 3. Execute updateLabel.ps1
#     Syntax: .\updateLabel.ps1 -servicePrincipal “c3652-adm@mainroads.wa.gov.au” -projectId “MR-30000597-MEBD-CON” -groupOwner “scott.white@mainroads.wa.gov.au” -domainName “group.mainroads.wa.gov.au” 
#
param ($servicePrincipal, $projectId, $groupOwner, $domainName)

#### Set reusable variables
# prefix for groups / names / etc
$prefix = $projectId

# Group Names
$groupNameManagement = "$prefix Project Management"
$groupNameSupport = "$prefix Project Support"
$groupNameEvalQualitative = "$prefix Eval Qualitative"
$groupNameEvalCommercial = "$prefix Eval Commercial"
$groupNameProbity = "$prefix Probity"
$groupNameLegal = "$prefix Legal"
$groupNameGovernance = "$prefix Governance"
$groupNameContractor = "$prefix Contractor"

# Alias
$aliasManagement = $groupNameManagement.replace(" ", "-")
$aliasSupport = $groupNameSupport.replace(" ", "-")
$aliasEvalQualitative = $groupNameEvalQualitative.replace(" ", "-")
$aliasEvalCommercial = $groupNameEvalCommercial.replace(" ", "-")
$aliasProbity = $groupNameProbity.replace(" ", "-")
$aliasLegal = $groupNameLegal.Replace(" ", "-")
$aliasGovernance = $groupNameGovernance.replace(" ", "-")
$aliasContractor = $groupNameContractor.replace(" ", "-")

#### Connect to Compliance Centre Remotely
Write-Host "Connecting to Compliance Centre"
Connect-IPPSSession -UserPrincipalName $servicePrincipal

# Label Names - cannot be changed (not the display names of the labels)
$lbNameTender = "$prefix-Tender"
$lbNameSubmissionQualitative = "$prefix-Submission-Qualitative"
$lbNameSubmissionCommercial = "$prefix-Submission-Commercial"
$lbNameEvalQualitative = "$prefix-Evaluation-Qualitative"
$lbNameEvalCommercial = "$prefix-Evaluation-Commercial"
$lbNameStrictlyConfidential = "$prefix-Strictly-Confidential"
$lbNameContractAward = "$prefix-Contract-Award"

### Creating new labels
Write-Host "Creating new sensitivity labels"
# Evaluation Qualitative
Write-Host "Creating $lbNameEvalQualitative label"
New-Label -Name $lbNameEvalQualitative -DisplayName "Evaluation Qualitative - Official Sensitive" -Tooltip "This label is to be applied to any evaluation qualitative documentation" -ContentType "File, Email" -EncryptionEnabled $true -EncryptionEncryptOnly $false -EncryptionProtectionType "Template" -EncryptionRightsDefinitions "$aliasSupport@$domainName`:OWNER;$aliasEvalQualitative@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,EXPORT,EXTRACT,OBJMODEL;$aliasEvalCommercial@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,EXPORT,EXTRACT,OBJMODEL;$aliasProbity@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$aliasLegal@$domainName`:VIEW,VIEWRIGHTSDATA,PRINT,EXTRACT,DOCEDIT,EDIT,EXPORT,OBJMODEL;$aliasGovernance@$domainName`:VIEW,VIEWRIGHTSDATA,PRINT,DOCEDIT,EDIT,OBJMODEL" -EncryptionOfflineAccessDays "-1" -ParentId $prefix
Write-Host "Done!"

# Evaluation Commercial
Write-Host "Creating $lbNameEvalCommercial label"
New-Label -Name $lbNameEvalCommercial -DisplayName "Evaluation Commercial - Official Sensitive" -Tooltip "This label is to be applied to any evaluation commercial documentation" -ContentType "File, Email" -EncryptionEnabled $true -EncryptionEncryptOnly $false -EncryptionProtectionType "Template" -EncryptionRightsDefinitions "$aliasSupport@$domainName`:OWNER;$aliasEvalCommercial@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,EXPORT,EXTRACT,OBJMODEL;$aliasProbity@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$aliasLegal@$domainName`:VIEW,VIEWRIGHTSDATA,PRINT,EXTRACT,DOCEDIT,EDIT,EXPORT,OBJMODEL;$aliasGovernance@$domainName`:VIEW,VIEWRIGHTSDATA,PRINT,DOCEDIT,EDIT,OBJMODEL" -EncryptionOfflineAccessDays "-1" -ParentId $prefix
Write-Host "Done!"

### Updating the existing label permissions 
Write-Host "Updating existing labels"

# Tender
Write-Host "Updating $lbNameTender label"
Set-Label -Identity $lbNameTender -EncryptionRightsDefinitions "$aliasManagement@$domainName`:VIEW,VIEWRIGHTSDATA,PRINT,EXTRACT,DOCEDIT,EDIT,EXPORT,OBJMODEL;$aliasSupport@$domainName`:OWNER;$aliasEvalQualitative@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$aliasEvalCommercial@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$aliasProbity@$domainName`:VIEW,VIEWRIGHTSDATA,PRINT,EXTRACT,DOCEDIT,EDIT,EXPORT,OBJMODEL;$aliasLegal@$domainName`:VIEW,VIEWRIGHTSDATA,PRINT,EXTRACT,DOCEDIT,EDIT,EXPORT,OBJMODEL;$aliasGovernance@$domainName`:VIEW,VIEWRIGHTSDATA,PRINT,EXTRACT,DOCEDIT,EDIT,EXPORT,OBJMODEL"
Write-Host "Done!"

#Submission Qualitative
Write-Host "Updating $lbNameSubmissionQualitative label"
Set-Label -Identity $lbNameSubmissionQualitative -EncryptionRightsDefinitions "$aliasSupport@$domainName`:OWNER;$aliasEvalQualitative@$domainName`:VIEW,VIEWRIGHTSDATA;$aliasEvalCommercial@$domainName`:VIEW,VIEWRIGHTSDATA;$aliasProbity@$domainName`:VIEW,VIEWRIGHTSDATA;$aliasLegal@$domainName`:VIEW,VIEWRIGHTSDATA,PRINT,EXTRACT,DOCEDIT,EDIT,EXPORT,OBJMODEL;$aliasGovernance@$domainName`:VIEW,VIEWRIGHTSDATA"
Write-Host "Done!"

#Submission Commercial
Write-Host "Updating $lbNameSubmissionCommercial label"
Set-Label -Identity $lbNameSubmissionCommercial -EncryptionRightsDefinitions "$aliasSupport@$domainName`:OWNER;$aliasEvalCommercial@$domainName`:VIEW,VIEWRIGHTSDATA;$aliasProbity@$domainName`:VIEW,VIEWRIGHTSDATA;$aliasLegal@$domainName`:VIEW,VIEWRIGHTSDATA,PRINT,EXTRACT,DOCEDIT,EDIT,EXPORT,OBJMODEL;$aliasGovernance@$domainName`:VIEW,VIEWRIGHTSDATA"
Write-Host "Done!"

# Strictly Confidential
Write-Host "Updating $lbNameStrictlyConfidential label"
Set-Label -Identity $lbNameStrictlyConfidential -EncryptionRightsDefinitions "$aliasManagement@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$aliasSupport@$domainName`:OWNER;$aliasEvalQualitative@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$aliasEvalCommercial@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$aliasProbity@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$aliasLegal@$domainName`:VIEW,VIEWRIGHTSDATA,PRINT,EXTRACT,DOCEDIT,EDIT,EXPORT,OBJMODEL;$aliasGovernance@$domainName`: VIEW,VIEWRIGHTSDATA,PRINT,EXTRACT,DOCEDIT,EDIT,EXPORT,OBJMODEL"
Write-Host "Done!"

#Contract Award
Write-Host "Updating $lbNameContractAward label"
Set-Label -Identity $lbNameContractAward -EncryptionRightsDefinitions "$aliasManagement@$domainName`:VIEW,VIEWRIGHTSDATA,OBJMODEL;$aliasSupport@$domainName`:OWNER;$aliasEvalQualitative@$domainName`:VIEW,VIEWRIGHTSDATA,OBJMODEL;$aliasEvalCommercial@$domainName`:VIEW,VIEWRIGHTSDATA,OBJMODEL;$aliasProbity@$domainName`:VIEW,VIEWRIGHTSDATA,OBJMODEL;$aliasLegal@$domainName`:VIEW,VIEWRIGHTSDATA,OBJMODEL;$aliasGovernance@$domainName`:VIEW,VIEWRIGHTSDATA,OBJMODEL;$aliasContractor@$domainName`: VIEW,VIEWRIGHTSDATA,PRINT,EXTRACT,DOCEDIT,EDIT,EXPORT,OBJMODEL"
Write-Host "Done!"

### Update the priority of newly created labels
Write-Host "Updating the priority of newly created labels"
# Get required priority
$priority = (Get-Label -Identity $lbNameTender).Priority

$priority++

# Evaluation Qualitative
Write-Host "Updating priority of $lbNameSubmissionQualitative label"
Set-Label -Identity $lbNameSubmissionQualitative -Priority $priority
Write-Host "Done!"

$priority++

# Evaluation Commercial
Write-Host "Updating priority of $lbNameSubmissionQualitative label"
Set-Label -Identity $lbNameSubmissionQualitative -Priority $priority
Write-Host "Done!"

# Update label policy
Write-Host "Updating the label policy"
Set-LabelPolicy -Identity "$prefix Label Policy" -AddLabels $lbNameEvalQualitative, $lbNameEvalCommercial -RemoveLabels "$prefix-Evaluation"
Write-Host "Done!"

##### Disconnect from Remote Connection
Write-Host "Disconnecting remote connections"
Disconnect-ExchangeOnline -Confirm:$false