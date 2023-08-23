#
# This script provisions M365 Groups, Sensitivity Labels, Label Policy, and DLP Policy that triggers when documents that has below defined sensitivity labels is shared outside the organization or print activity is performed on endpoint devices
#           - General 
#           - Strictly Confidential
# Version 0.1.0
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
#    $emailToSendNotification (optional) - the FQDN of the person that to whom email notification is triggered when DLP policy is matched
#    
### Provisioning Instructions ### 
# 1. Ensure prerequisites are completed
# 2. Browse to the script directory
#     cd "<script_location_in_file_system>"
# 3. Execute LabelAutomation.ps11 (In the syntax $emailToSendNotification parameter is optional)
#     Syntax: .\LabelAutomation.ps1 -servicePrincipal "c3652-adm@mainroads.wa.gov.au" -projectId "MR-30002775-MPC-PRJ" -groupOwner "scott.white@mainroads.wa.gov.au" -domainName "group.mainroads.wa.gov.au"
#

param (
    [parameter(Mandatory=$true)] $servicePrincipal,
    [parameter(Mandatory=$true)] $projectId,
    [parameter(Mandatory=$true)] $groupOwner,
    [parameter(Mandatory=$true)] $domainName, 
    [parameter(Mandatory=$false)] $emailToSendNotification
)

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

# Alias
$aliasManagement = $groupNameManagement.replace(" ", "-")
$aliasSupport = $groupNameSupport.replace(" ", "-")

$ownerEmail = $groupOwner.Trim('"')
$emailArray = $ownerEmail -split ','
$ownerEmails = $emailArray | ForEach-Object { "`"$_`"" } -join ','

#### Create M365 Groups
Write-Host "Creating M365 Groups..."

# Project Management
Write-Host "Creating $groupNameManagement group..."
New-UnifiedGroup -DisplayName $groupNameManagement -Alias $aliasManagement -AccessType "Private" -Owner $servicePrincipal
Set-UnifiedGroup -Identity $aliasManagement -UnifiedGroupWelcomeMessageEnabled:$false
Add-UnifiedGroupLinks -Identity $aliasManagement -LinkType "Members" -Links $ownerEmails
Add-UnifiedGroupLinks -Identity $aliasManagement -LinkType "Owners" -Links $ownerEmails

# Project Support
Write-Host "Creating $groupNameSupport group..."
New-UnifiedGroup -DisplayName $groupNameSupport -Alias $aliasSupport -AccessType "Private" -Owner $servicePrincipal
Set-UnifiedGroup -Identity $aliasSupport -UnifiedGroupWelcomeMessageEnabled:$false
Add-UnifiedGroupLinks -Identity $aliasSupport -LinkType "Members" -Links $ownerEmails
Add-UnifiedGroupLinks -Identity $aliasSupport -LinkType "Owners" -Links $ownerEmails

#### Connect to Compliance Centre Remotely
Write-Host "Connecting to Compliance centre"
Connect-IPPSSession -UserPrincipalName $servicePrincipal

##### Create Labels
### Parent Labels
# Top-Level
Write-Host "Creating Parent label $prefix..."
New-Label -Name $prefix -DisplayName $prefix -Tooltip "This is the top-level label for all project labels" -EncryptionEnabled $false

# Label Names - cannot be changed (not the display names of the labels)
$lbNameGeneral = "$prefix-General"
$lbNameStrictlyConfidential = "$prefix-Strictly-Confidential"
$lbNameForRelease = "$prefix-For-Release"

### Child Labels
Write-Host "Creating Child labels..."
# General
Write-Host "Creating $lbNameGeneral label..."
New-Label -Name $lbNameGeneral -DisplayName "General - Official Sensitive" -Tooltip "This label is to be applied to any general documents" -ContentType "File, Email" -EncryptionEnabled $true -EncryptionEncryptOnly $false -EncryptionProtectionType "Template" -EncryptionRightsDefinitions "$aliasManagement@$domainName`:VIEW,VIEWRIGHTSDATA,PRINT,EXTRACT,DOCEDIT,EDIT,EXPORT,OBJMODEL;$aliasSupport@$domainName`:OWNER" -EncryptionOfflineAccessDays "-1" -ParentId $prefix 

# Strictly Confidential
Write-Host "Creating $lbNameStrictlyConfidential label..."
New-Label -Name $lbNameStrictlyConfidential -DisplayName "Strictly Confidential - Official Sensitive" -Tooltip "This label is to be applied to any document that is deemed strictly confidential in nature" -ContentType "File, Email" -EncryptionEnabled $true -EncryptionEncryptOnly $false -EncryptionProtectionType "Template" -EncryptionRightsDefinitions "$aliasManagement@$domainName`:VIEW,VIEWRIGHTSDATA,DOCEDIT,EDIT,OBJMODEL;$aliasSupport@$domainName`:OWNER" -EncryptionOfflineAccessDays "-1" -ParentId $prefix

# For Release
Write-Host "Creating $lbNameForRelease label..."
New-Label -Name $lbNameForRelease -DisplayName "For Release - Official Sensitive" -Tooltip "This label is to be applied prior to releasing protected documents to external parties" -ContentType "File, Email" -EncryptionEnabled $true -EncryptionEncryptOnly $false -EncryptionProtectionType "RemoveProtection" -ParentId $prefix

##### Create Label Policy
Write-Host "Creating '$prefix Label Policy' label policy..."
New-LabelPolicy -Name "$prefix Label Policy" -Labels $prefix, $lbNameGeneral, $lbNameSubmissionQualitative, $lbNameSubmissionCommercial, $lbNameEvalQualitative, $lbNameEvalCommercial, $lbNameStrictlyConfidential, $lbNameContractAward, $lbNameForRelease -ModernGroupLocation "$aliasSupport@$domainName" -AdvancedSettings @{requiredowngradejustification = "true"; siteandgroupmandatory = "false"; mandatory = "false"; disablemandatoryinoutlook = "true"; EnableCustomPermissions = "False" }


### Creating DLP policy

$externalSharingPolicyName = "Notification-When-Shared-External-IDDP"
$externalSharingRuleName = "$prefix-External-Sharing"
$description = "Applies DLP action based on the Classification levels. Will create email incident reports on documents that are labelled as 'General', 'Strictly Confidential' and are being shared externally"

if (![string]::IsNullOrEmpty($emailToSendNotification)) {
    $generateIncidentReport = @(
        $emailToSendNotification
    )
    $incidentReportContent = @(
        "Title"
        "DocumentAuthor"
        "DocumentLastModifier"
        "Service"
        "MatchedItem"
        "RulesMatched"
        "Detections"
        "Severity"
        "DetectionDetails"
        "RetentionLabel"
        "SensitivityLabel"
    )
}

# Condition for when to trigger DLP
# This parameter is used to match all the documents which has one of these sensitivity labels
$sensitivityLabels = @(
    @{
        operator = "And";
        groups   = @(
            @{
                operator = "Or";
                name     = "Default";
                labels   = @(
                    @{
                        name = $lbNameGeneral; 
                        type = "Sensitivity"
                    };
                    @{
                        name = $lbNameContractAward;
                        type = "Sensitivity"
                    }
                ) 
            }
        ) 
    }  
)

## Check if DLP policy already exists or not. If exists only add the DLP compliance rule else create DLP compliance policy and add compliance rule
$dlpNames = (Get-DlpCompliancePolicy).Name
$doesPolicyAlreadyExists = $false
foreach ($name in $dlpNames) {
    if ($name -eq $externalSharingPolicyName) {
        $doesPolicyAlreadyExists = $true
        Break
    }
}

# Creates a DLP policy ONLY IF IT IS ALREADY NOT PRESENT targeting all sharepoint location and exchange location.
if (!$doesPolicyAlreadyExists) {
    Write-Host "Creating DLP Policy..."
    New-DlpCompliancePolicy -Name $externalSharingPolicyName -Comment $description -SharePointLocation All -ExchangeLocation All -Mode Enable
}

# Check if the dlp compliance rule already exists or not. If not then only create new one
$dlpRuleNames = (Get-DlpComplianceRule).Name
$doesRuleAlreadyExists = $false
foreach ($name in $dlpRuleNames) {
    if ($name -eq $externalSharingRuleName) {
        $doesRuleAlreadyExists = $true
        Break
    }
}

# Create a rule in the above created DLP to trigger notification when any documents with that has below mentioned sensitivity label applied and are shared outside the organization
#           - General
#           - Strictly Confidential
if (!$doesRuleAlreadyExists) {
    Write-Host "Creating rule for DLP Policy..."
    if ([string]::IsNullOrEmpty($emailToSendNotification)) {
        New-DlpComplianceRule -Name $externalSharingRuleName -Policy $externalSharingPolicyName -AccessScope NotInOrganization -ContentContainsSensitiveInformation $sensitivityLabels
    } else {
        New-DlpComplianceRule -Name $externalSharingRuleName -Policy $externalSharingPolicyName -AccessScope NotInOrganization -ContentContainsSensitiveInformation $sensitivityLabels -GenerateIncidentReport $generateIncidentReport -IncidentReportContent $incidentReportContent
    }
}

## DLP for Print Activity on endpoint devices.
$devicePrintActivityPolicyName = "Notification-for-Print-Activity-IDDP"
$devicePrintActivityRuleName = "$prefix-Print-Activity"
$description = "Applies DLP action based on the Classification levels. Will create email incident reports on documents that are labelled as 'General', 'Strictly Confidential' and print activities are performed on device"
if (![string]::IsNullOrEmpty($emailToSendNotification)) {
    $emailForAlert = $emailToSendNotification
}

# The type of audit or restrict activities to be performed on devices
$endpointDlpSettings = @(
    @{
        "Setting" = "CopyPaste";
        "Value"   = "Audit"
    },
    @{
        "Setting" = "RemovableMedia";
        "Value"   = "Audit"
    },
    @{
        "Setting" = "NetworkShare";
        "Value"   = "Audit"
    },
    @{
        "Setting" = "Print";
        "Value"   = "Audit"
    },
    @{
        "Setting" = "RemoteDesktopServices";
        "Value"   = "Audit"
    }
)
## Check if DLP policy already exists or not. If exists only add the DLP compliance rule else create DLP compliance policy and add compliance rule
$doesPolicyAlreadyExists = $false
foreach ($name in $dlpNames) {
    if ($name -eq $devicePrintActivityPolicyName) {
        $doesPolicyAlreadyExists = $true
        Break
    }
}
if (!$doesPolicyAlreadyExists) {
    Write-Host "Creating DLP Policy..."
    New-DlpCompliancePolicy -Name $devicePrintActivityPolicyName -Comment $description -EndpointDlpLocation All -Mode Enable
}

# Check if the DLP compliance rule already exists or not. Add the rule if only it does not exist already.
$dlpRuleNames = (Get-DlpComplianceRule).Name
$doesRuleAlreadyExists = $false
foreach ($name in $dlpRuleNames) {
    if ($name -eq $devicePrintActivityRuleName) {
        $doesRuleAlreadyExists = $true
        Break
    }
}
if (!$doesRuleAlreadyExists) {
    Write-Host "Creating rule for DLP Policy..."
    if (![string]::IsNullOrEmpty($emailToSendNotification)) {
        New-DlpComplianceRule -Name $devicePrintActivityRuleName -Policy $devicePrintActivityPolicyName  -ContentContainsSensitiveInformation $sensitivityLabels -EndpointDlpRestrictions $endpointDlpSettings -GenerateAlert $emailForAlert
    } else {
        New-DlpComplianceRule -Name $devicePrintActivityRuleName -Policy $devicePrintActivityPolicyName  -ContentContainsSensitiveInformation $sensitivityLabels -EndpointDlpRestrictions $endpointDlpSettings
    }
}

##### Disconnect from Remote Connection
Disconnect-ExchangeOnline -Confirm:$false
