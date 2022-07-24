#
# This script provisions M365 Groups, Sensitivity Labels and Label Policy
# Version 0.4
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

#### Create M365 Groups

# Project Management
New-UnifiedGroup -DisplayName "$prefix Project Management" -Alias "$prefix-Project-Management" -AccessType "Private" -Owner $groupOwner
Set-UnifiedGroup -Identity "$prefix-Project-Management" -UnifiedGroupWelcomeMessageEnabled:$false

# Project Support
New-UnifiedGroup -DisplayName "$prefix Project Support" -Alias "$prefix-Project-Support" -AccessType "Private" -Owner $groupOwner
Set-UnifiedGroup -Identity "$prefix-Project-Support" -UnifiedGroupWelcomeMessageEnabled:$false

# Evaluation Team - Qualitative
New-UnifiedGroup -DisplayName "$prefix Eval Qualitative" -Alias "$prefix-Eval-Qualitative" -AccessType "Private" -Owner $groupOwner
Set-UnifiedGroup -Identity "$prefix-Eval-Qualitative" -UnifiedGroupWelcomeMessageEnabled:$false

# Evaluation Team - Commercial
New-UnifiedGroup -DisplayName "$prefix Eval Commercial" -Alias "$prefix-Eval-Commercial" -AccessType "Private" -Owner $groupOwner
Set-UnifiedGroup -Identity "$prefix-Eval-Commercial" -UnifiedGroupWelcomeMessageEnabled:$false

# Probity
New-UnifiedGroup -DisplayName "$prefix Probity" -Alias "$prefix-Probity" -AccessType "Private" -Owner $groupOwner
Set-UnifiedGroup -Identity "$prefix-Probity" -UnifiedGroupWelcomeMessageEnabled:$false

# Governance
New-UnifiedGroup -DisplayName "$prefix Governance" -Alias "$prefix-Governance" -AccessType "Private" -Owner $groupOwner
Set-UnifiedGroup -Identity "$prefix-Governance" -UnifiedGroupWelcomeMessageEnabled:$false

# Applicant/Proponent
New-UnifiedGroup -DisplayName "$prefix Applicant/Proponent" -Alias "$prefix-Applicant/Proponent" -AccessType "Private" -Owner $groupOwner
Set-UnifiedGroup -Identity "$prefix-Applicant/Proponent" -UnifiedGroupWelcomeMessageEnabled:$false

#### Connect to Compliance Centre Remotely
Connect-IPPSSession -UserPrincipalName $servicePrincipal

##### Create Labels
### Parent Labels
# Top-Level
New-Label -Name $prefix -DisplayName $prefix -Tooltip "This is the top-level label for all project labels" -EncryptionEnabled $false

### Child Labels
# Tender
New-Label -Name "$prefix-Tender" -DisplayName "Tender - Official Sensitive" -Tooltip "This label is to be applied to any tender documents" -ContentType "File, Email" -EncryptionEnabled $true -EncryptionEncryptOnly $false -EncryptionProtectionType "Template" -EncryptionRightsDefinitions "$prefix-Project-Management@$domainName`:VIEW,VIEWRIGHTSDATA,PRINT,EXTRACT,DOCEDIT,EDIT,EXPORT,OBJMODEL;$prefix-Project-Support@$domainName`:OWNER;$prefix-Eval-Qualitative@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$prefix-Eval-Commercial@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$prefix-Probity-Legal@$domainName`:VIEW,VIEWRIGHTSDATA,PRINT,EXTRACT,DOCEDIT,EDIT,EXPORT,OBJMODEL;$prefix-Project-Governance@$domainName`:VIEW,VIEWRIGHTSDATA,PRINT,EXTRACT,DOCEDIT,EDIT,EXPORT,OBJMODEL" -EncryptionOfflineAccessDays "-1" -ParentId $prefix 

# Submission
New-Label -Name "$prefix-Submission" -DisplayName "Submission - Official Sensitive" -Tooltip "This label is to be applied to all documents submitted by a proponent or applicant" -ContentType "File, Email" -EncryptionEnabled $true -EncryptionEncryptOnly $false -EncryptionProtectionType "Template" -EncryptionRightsDefinitions "$prefix-Project-Support@$domainName`:OWNER;$prefix-Eval-Qualitative@$domainName`:VIEW,VIEWRIGHTSDATA,OBJMODEL;$prefix-Eval-Commercial@$domainName`:VIEW,VIEWRIGHTSDATA,OBJMODEL;$prefix-Probity-Legal@$domainName`:VIEW,VIEWRIGHTSDATA,OBJMODEL;$prefix-Project-Governance@$domainName`:VIEW,VIEWRIGHTSDATA,OBJMODEL" -EncryptionOfflineAccessDays "-1" -ParentId $prefix

# Evaluation
New-Label -Name "$prefix-Evaluation" -DisplayName "Evaluation - Official Sensitive" -Tooltip "This label is to be applied to any evaluation documentation" -ContentType "File, Email" -EncryptionEnabled $true -EncryptionEncryptOnly $false -EncryptionProtectionType "Template" -EncryptionRightsDefinitions "$prefix-Project-Support@$domainName`:OWNER;$prefix-Eval-Qualitative@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$prefix-Eval-Commercial@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$prefix-Probity-Legal@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$prefix-Project-Governance@$domainName`:VIEW,VIEWRIGHTSDATA,PRINT,DOCEDIT,EDIT,OBJMODEL" -EncryptionOfflineAccessDays "-1" -ParentId $prefix

# Strictly Confidential
New-Label -Name "$prefix-Strictly-Confidential" -DisplayName "Strictly Confidential - Official Sensitive" -Tooltip "This label is to be applied to any document that is deemed strictly confidential in nature" -ContentType "File, Email" -EncryptionEnabled $true -EncryptionEncryptOnly $false -EncryptionProtectionType "Template" -EncryptionRightsDefinitions "$prefix-Project-Management@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$prefix-Project-Support@$domainName`:OWNER;$prefix-Eval-Qualitative@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$prefix-Eval-Commercial@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$prefix-Probity-Legal@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$prefix-Project-Governance@$domainName`: VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL" -EncryptionOfflineAccessDays "-1" -ParentId $prefix

# Contract Award
New-Label -Name "$prefix-Contract-Award" -DisplayName "Contract Award - Official Sensitive" -Tooltip "This label is to be applied to documents relating to the awarded contract where a contractor needs to sign award documentation" -ContentType "File, Email" -EncryptionEnabled $true -EncryptionEncryptOnly $false -EncryptionProtectionType "Template" -EncryptionRightsDefinitions "$prefix-Project-Management@$domainName`:VIEW,VIEWRIGHTSDATA,PRINT,EXTRACT,DOCEDIT,EDIT,EXPORT,OBJMODEL;$prefix-Project-Support@$domainName`:OWNER;$prefix-Eval-Qualitative@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$prefix-Eval-Commercial@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$prefix-Probity-Legal@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$prefix-Project-Governance@$domainName`: VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL" -EncryptionOfflineAccessDays "-1" -ParentId $prefix 

# For Release
New-Label -Name "$prefix-For-Release" -DisplayName "For Release - Official Sensitive" -Tooltip "This label is to be applied prior to releasing protected documents to external parties" -ContentType "File, Email" -EncryptionEnabled $true -EncryptionEncryptOnly $false -EncryptionProtectionType "RemoveProtection" -ParentId $prefix

##### Create Label Policy
New-LabelPolicy -Name "$prefix Label Policy" -Labels $prefix, "$prefix-Tender", "$prefix-Submission", "$prefix-Evaluation", "$prefix-Strictly-Confidential", "$prefix-Contract-Award", "$prefix-For-Release" -ModernGroupLocation "$prefix-Project-Support@$domainName" -AdvancedSettings @{requiredowngradejustification="true"; siteandgroupmandatory="false"; mandatory="false"; disablemandatoryinoutlook="true"; EnableCustomPermissions="False"}

##### Disconnect from Remote Connection
Disconnect-ExchangeOnline -Confirm:$false
