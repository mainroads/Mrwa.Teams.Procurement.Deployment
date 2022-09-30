#
# This script provisions M365 Groups, Sensitivity Labels and Label Policy
# Version 0.6
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
#     Syntax: .\LabelAutomation.ps1 -servicePrincipal “c3652-adm@mainroads.wa.gov.au” -projectId “MR-30000597-MEBD-PRJ” -groupOwner “scott.white@mainroads.wa.gov.au” -domainName “group.mainroads.wa.gov.au” 
#

param ($servicePrincipal, $projectId, $groupOwner, $domainName)

#### Import the Exchange Online Management Module
Write-Host "Connecting to Exchange Online centre"
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
$groupNameLegal = "$prefix Legal"
$groupNameGovernance = "$prefix Governance"
$groupNameContractor = "$prefix Contractor"

# Alias
$aliasManagement = $groupNameManagement.replace(" ", "-")
$aliasSupport = $groupNameSupport.replace(" ", "-")
$aliasEvalQualitative = $groupNameEvalQualitative.replace(" ", "-")
$aliasEvalCommercial = $groupNameEvalCommercial.replace(" ", "-")
$aliasProbity = $groupNameProbity.replace(" ", "-")
$aliasGovernance = $groupNameGovernance.replace(" ", "-")
$aliasLegal = $groupNameLegal.Replace(" ", "-")
$aliasContractor = $groupNameContractor.replace(" ", "-")

#### Create M365 Groups
Write-Host "Creating M365 Groups..."

# Project Management
Write-Host "Creating $groupNameManagement group..."
New-UnifiedGroup -DisplayName $groupNameManagement -Alias $aliasManagement -AccessType "Private" -Owner $groupOwner
Set-UnifiedGroup -Identity $aliasManagement -UnifiedGroupWelcomeMessageEnabled:$false

# Project Support
Write-Host "Creating $groupNameSupport group..."
New-UnifiedGroup -DisplayName $groupNameSupport -Alias $aliasSupport -AccessType "Private" -Owner $groupOwner
Set-UnifiedGroup -Identity $aliasSupport -UnifiedGroupWelcomeMessageEnabled:$false

# Evaluation Team - Qualitative
Write-Host "Creating $groupNameEvalQualitative group..."
New-UnifiedGroup -DisplayName $groupNameEvalQualitative -Alias $aliasEvalQualitative -AccessType "Private" -Owner $groupOwner
Set-UnifiedGroup -Identity $aliasEvalQualitative -UnifiedGroupWelcomeMessageEnabled:$false

# Evaluation Team - Commercial
Write-Host "Creating $groupNameEvalCommercial group..."
New-UnifiedGroup -DisplayName $groupNameEvalCommercial -Alias $aliasEvalCommercial -AccessType "Private" -Owner $groupOwner
Set-UnifiedGroup -Identity $aliasEvalCommercial -UnifiedGroupWelcomeMessageEnabled:$false

# Probity
Write-Host "Creating $groupNameProbity group..."
New-UnifiedGroup -DisplayName $groupNameProbity -Alias $aliasProbity -AccessType "Private" -Owner $groupOwner
Set-UnifiedGroup -Identity $aliasProbity -UnifiedGroupWelcomeMessageEnabled:$false

# Legal
Write-Host "Creating $groupNameLegal group..."
New-UnifiedGroup -DisplayName $groupNameLegal -Alias $aliasLegal -AccessType "Private" -Owner $groupOwner
Set-UnifiedGroup -Identity $aliasLegal -UnifiedGroupWelcomeMessageEnabled:$false

# Governance
Write-Host "Creating $groupNameGovernance group..."
New-UnifiedGroup -DisplayName $groupNameGovernance -Alias $aliasGovernance -AccessType "Private" -Owner $groupOwner
Set-UnifiedGroup -Identity $aliasGovernance -UnifiedGroupWelcomeMessageEnabled:$false

# Contractor
Write-Host "Creating $groupNameContractor group..."
New-UnifiedGroup -DisplayName $groupNameContractor -Alias $aliasContractor -AccessType "Private" -Owner $groupOwner
Set-UnifiedGroup -Identity $aliasContractor -UnifiedGroupWelcomeMessageEnabled:$false

#### Connect to Compliance Centre Remotely
Write-Host "Connecting to Compliance centre"
Connect-IPPSSession -UserPrincipalName $servicePrincipal

##### Create Labels
### Parent Labels
# Top-Level
Write-Host "Creating Parent label $prefix..."
New-Label -Name $prefix -DisplayName $prefix -Tooltip "This is the top-level label for all project labels" -EncryptionEnabled $false

# Label Names - cannot be changed (not the display names of the labels)
$lbNameTender = "$prefix-Tender"
$lbNameSubmissionQualitative = "$prefix-Submission-Qualitative"
$lbNameSubmissionCommercial = "$prefix-Submission-Commercial"
$lbNameEvalQualitative = "$prefix-Evaluation-Qualitative"
$lbNameEvalCommercial = "$prefix-Evaluation-Commercial"
$lbNameStrictlyConfidential = "$prefix-Strictly-Confidential"
$lbNameContractAward = "$prefix-Contract-Award"
$lbNameForRelease = "$prefix-For-Release"

### Child Labels
Write-Host "Creating Child labels..."
# Tender
Write-Host "Creating $lbNameTender label..."
New-Label -Name $lbNameTender -DisplayName "Tender - Official Sensitive" -Tooltip "This label is to be applied to any tender documents" -ContentType "File, Email" -EncryptionEnabled $true -EncryptionEncryptOnly $false -EncryptionProtectionType "Template" -EncryptionRightsDefinitions "$aliasManagement@$domainName`:VIEW,VIEWRIGHTSDATA,PRINT,EXTRACT,DOCEDIT,EDIT,EXPORT,OBJMODEL;$aliasSupport@$domainName`:OWNER;$aliasEvalQualitative@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$aliasEvalCommercial@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$aliasProbity@$domainName`:VIEW,VIEWRIGHTSDATA,PRINT,EXTRACT,DOCEDIT,EDIT,EXPORT,OBJMODEL;$aliasLegal@$domainName`:VIEW,VIEWRIGHTSDATA,PRINT,EXTRACT,DOCEDIT,EDIT,EXPORT,OBJMODEL;$aliasGovernance@$domainName`:VIEW,VIEWRIGHTSDATA,PRINT,EXTRACT,DOCEDIT,EDIT,EXPORT,OBJMODEL" -EncryptionOfflineAccessDays "-1" -ParentId $prefix 

# Submission Qualitative
Write-Host "Creating $lbNameSubmissionQualitative label..."
New-Label -Name $lbNameSubmissionQualitative -DisplayName "Submission Qualitative - Official Sensitive" -Tooltip "This label is to be applied to any submission qualitative documentation" -ContentType "File, Email" -EncryptionEnabled $true -EncryptionEncryptOnly $false -EncryptionProtectionType "Template" -EncryptionRightsDefinitions "$aliasSupport@$domainName`:OWNER;$aliasEvalQualitative@$domainName`:VIEW,VIEWRIGHTSDATA;$aliasEvalCommercial@$domainName`:VIEW,VIEWRIGHTSDATA;$aliasProbity@$domainName`:VIEW,VIEWRIGHTSDATA;$aliasLegal@$domainName`:VIEW,VIEWRIGHTSDATA,PRINT,EXTRACT,DOCEDIT,EDIT,EXPORT,OBJMODEL;$aliasGovernance@$domainName`:VIEW,VIEWRIGHTSDATA" -EncryptionOfflineAccessDays "-1" -ParentId $prefix

# Submission Commercial
Write-Host "Creating $lbNameSubmissionCommercial label..."
New-Label -Name $lbNameSubmissionCommercial -DisplayName "Submission Commercial - Official Sensitive" -Tooltip "This label is to be applied to any submission commercial documentation" -ContentType "File, Email" -EncryptionEnabled $true -EncryptionEncryptOnly $false -EncryptionProtectionType "Template" -EncryptionRightsDefinitions "$aliasSupport@$domainName`:OWNER;$aliasEvalCommercial@$domainName`:VIEW,VIEWRIGHTSDATA;$aliasProbity@$domainName`:VIEW,VIEWRIGHTSDATA;$aliasLegal@$domainName`:VIEW,VIEWRIGHTSDATA,PRINT,EXTRACT,DOCEDIT,EDIT,EXPORT,OBJMODEL;$aliasGovernance@$domainName`:VIEW,VIEWRIGHTSDATA" -EncryptionOfflineAccessDays "-1" -ParentId $prefix

# Evaluation Qualitative
Write-Host "Creating $lbNameEvalQualitative label..."
New-Label -Name $lbNameEvalQualitative -DisplayName "Evaluation Qualitative - Official Sensitive" -Tooltip "This label is to be applied to any evaluation qualitative documentation" -ContentType "File, Email" -EncryptionEnabled $true -EncryptionEncryptOnly $false -EncryptionProtectionType "Template" -EncryptionRightsDefinitions "$aliasSupport@$domainName`:OWNER;$aliasEvalQualitative@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,EXPORT,EXTRACT,OBJMODEL;$aliasEvalCommercial@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,EXPORT,EXTRACT,OBJMODEL;$aliasProbity@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$aliasLegal@$domainName`:VIEW,VIEWRIGHTSDATA,PRINT,EXTRACT,DOCEDIT,EDIT,EXPORT,OBJMODEL;$aliasGovernance@$domainName`:VIEW,VIEWRIGHTSDATA,PRINT,DOCEDIT,EDIT,OBJMODEL" -EncryptionOfflineAccessDays "-1" -ParentId $prefix

# Evaluation Commercial
Write-Host "Creating $lbNameEvalCommercial label..."
New-Label -Name $lbNameEvalCommercial -DisplayName "Evaluation Commercial - Official Sensitive" -Tooltip "This label is to be applied to any evaluation commercial documentation" -ContentType "File, Email" -EncryptionEnabled $true -EncryptionEncryptOnly $false -EncryptionProtectionType "Template" -EncryptionRightsDefinitions "$aliasSupport@$domainName`:OWNER;$aliasEvalCommercial@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,EXPORT,EXTRACT,OBJMODEL;$aliasProbity@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$aliasLegal@$domainName`:VIEW,VIEWRIGHTSDATA,PRINT,EXTRACT,DOCEDIT,EDIT,EXPORT,OBJMODEL;$aliasGovernance@$domainName`:VIEW,VIEWRIGHTSDATA,PRINT,DOCEDIT,EDIT,OBJMODEL" -EncryptionOfflineAccessDays "-1" -ParentId $prefix

# Strictly Confidential
Write-Host "Creating $lbNameStrictlyConfidential label..."
New-Label -Name $lbNameStrictlyConfidential -DisplayName "Strictly Confidential - Official Sensitive" -Tooltip "This label is to be applied to any document that is deemed strictly confidential in nature" -ContentType "File, Email" -EncryptionEnabled $true -EncryptionEncryptOnly $false -EncryptionProtectionType "Template" -EncryptionRightsDefinitions "$aliasManagement@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$aliasSupport@$domainName`:OWNER;$aliasEvalQualitative@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$aliasEvalCommercial@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$aliasProbity@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$aliasLegal@$domainName`:VIEW,VIEWRIGHTSDATA,PRINT,EXTRACT,DOCEDIT,EDIT,EXPORT,OBJMODEL;$aliasGovernance@$domainName`: VIEW,VIEWRIGHTSDATA,PRINT,EXTRACT,DOCEDIT,EDIT,EXPORT,OBJMODEL" -EncryptionOfflineAccessDays "-1" -ParentId $prefix

# Contract Award
Write-Host "Creating $lbNameContractAward label..."
New-Label -Name $lbNameContractAward -DisplayName "Contract Award - Official Sensitive" -Tooltip "This label is to be applied to documents relating to the awarded contract where a contractor needs to sign award documentation" -ContentType "File, Email" -EncryptionEnabled $true -EncryptionEncryptOnly $false -EncryptionProtectionType "Template" -EncryptionRightsDefinitions "$aliasManagement@$domainName`:VIEW,VIEWRIGHTSDATA,OBJMODEL;$aliasSupport@$domainName`:OWNER;$aliasEvalQualitative@$domainName`:VIEW,VIEWRIGHTSDATA,OBJMODEL;$aliasEvalCommercial@$domainName`:VIEW,VIEWRIGHTSDATA,OBJMODEL;$aliasProbity@$domainName`:VIEW,VIEWRIGHTSDATA,OBJMODEL;$aliasLegal@$domainName`:VIEW,VIEWRIGHTSDATA,OBJMODEL;$aliasGovernance@$domainName`:VIEW,VIEWRIGHTSDATA,OBJMODEL;$aliasContractor@$domainName`: VIEW,VIEWRIGHTSDATA,PRINT,EXTRACT,DOCEDIT,EDIT,EXPORT,OBJMODEL" -EncryptionOfflineAccessDays "-1" -ParentId $prefix 

# For Release
Write-Host "Creating $lbNameForRelease label..."
New-Label -Name $lbNameForRelease -DisplayName "For Release - Official Sensitive" -Tooltip "This label is to be applied prior to releasing protected documents to external parties" -ContentType "File, Email" -EncryptionEnabled $true -EncryptionEncryptOnly $false -EncryptionProtectionType "RemoveProtection" -ParentId $prefix

##### Create Label Policy
Write-Host "Creating '$prefix Label Policy' label policy..."
New-LabelPolicy -Name "$prefix Label Policy" -Labels $prefix, $lbNameTender, $lbNameSubmissionQualitative, $lbNameSubmissionCommercial, $lbNameEvalQualitative, $lbNameEvalCommercial, $lbNameStrictlyConfidential, $lbNameContractAward, $lbNameForRelease -ModernGroupLocation "$aliasSupport@$domainName" -AdvancedSettings @{requiredowngradejustification = "true"; siteandgroupmandatory = "false"; mandatory = "false"; disablemandatoryinoutlook = "true"; EnableCustomPermissions = "False" }

##### Disconnect from Remote Connection
Disconnect-ExchangeOnline -Confirm:$false
