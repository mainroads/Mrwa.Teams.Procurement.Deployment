#
# This script provisions DLP Policy to trigger notification when documents with following sensitivity labels are shared outside the organization
#           - Tender 
#           - Submissions Qualitative
#           - Submissions Commercial 
#           - Evaluation Qualitative 
#           - Evaluation Commercial
#           - Strictly Confidential
#           - Contract Award
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
#    $emailToSendNotification - the FQDN of the person that to whom email notification is triggered when DLP policy is matched
#    
### Provisioning Instructions ### 
# 1. Ensure prerequisites are completed
# 2. Browse to the script directory
#     cd "<script_location_in_file_system>"
# 3. Execute LabelAutomation.ps11
#     Syntax: .\dlpPolicy.ps1 -servicePrincipal "c3652-adm@mainroads.wa.gov.au" -projectId "MR-30000597-MEBD-CON" -emailToSendNotification "iddprocurementservices@mainroads.wa.gov.au"
#

param ($servicePrincipal, $projectId, $emailToSendNotification)

#### Import the Exchange Online Management Module
Write-Host "Connecting to Exchange Online centre"
Import-Module ExchangeOnlineManagement
Connect-IPPSSession -UserPrincipalName $servicePrincipal

#### Set reusable variables
# prefix for groups 
$prefix = $projectId

$lbNameTender = "$prefix-Tender"
$lbNameSubmissionQualitative = "$prefix-Submission-Qualitative"
$lbNameSubmissionCommercial = "$prefix-Submission-Commercial"
$lbNameEvalQualitative = "$prefix-Evaluation-Qualitative"
$lbNameEvalCommercial = "$prefix-Evaluation-Commercial"
$lbNameStrictlyConfidential = "$prefix-Strictly-Confidential"
$lbNameContractAward = "$prefix-Contract-Award"


$externlSharingPolicyName = "Notification-When-Shared-External-IDDP"
$externalSharingRuleName = "$prefix-External-Sharing"
$description = "Applies DLP action based on the Classification levels. Will create email incident reports on documents that are labelled as 'Tender', 'Submission Qualitative' , 'Submission Commercial', 'Evaluation Qualitative', 'Evaluation Commercial', 'Strictly Confidential', and/or 'Contract Award' and are being shared externally"

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

$sensitivityLabels = @(
    @{
        operator = "And";
        groups   = @(
            @{
                operator = "Or";
                name     = "Default";
                labels   = @(
                    @{
                        name = $lbNameTender; 
                        type = "Sensitivity"
                    };
                    @{
                        name = $lbNameSubmissionQualitative;
                        type = "Sensitivity"
                    };
                    @{
                        name = $lbNameSubmissionCommercial;
                        type = "Sensitivity"
                    };
                    @{
                        name = $lbNameEvalQualitative;
                        type = "Sensitivity"
                    };
                    @{
                        name = $lbNameEvalCommercial;
                        type = "Sensitivity"
                    };
                    @{
                        name = $lbNameStrictlyConfidential;
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

$dlpNames = (Get-DlpCompliancePolicy).Name
$doesPolicyAlreadyExists = $false
foreach ($name in $dlpNames) {
    if ($name -eq $externlSharingPolicyName) {
        $doesPolicyAlreadyExists = $true
        Break
    }
}

if (!$doesPolicyAlreadyExists) {
    New-DlpCompliancePolicy -Name $externlSharingPolicyName -Comment $description -SharePointLocation All -ExchangeLocation All -Mode Disable
}

$dlpRuleNames = (Get-DlpComplianceRule).Name
$doesRuleAlreadyExists = $false
foreach ($name in $dlpRuleNames) {
    if ($name -eq $externalSharingRuleName) {
        $doesRuleAlreadyExists = $true
        Break
    }
}
if (!$doesRuleAlreadyExists) {
    New-DlpComplianceRule -Name $externalSharingRuleName -Policy $externlSharingPolicyName -AccessScope NotInOrganization -ContentContainsSensitiveInformation $sensitivityLabels -GenerateIncidentReport $generateIncidentReport -IncidentReportContent $incidentReportContent
}

# DLP for Print Activity on endpoint devices.
$devicePrintActivityPolicyName = "Notification-for-Print-Activity-IDDP"
$devicePrintActivityRuleName = "$prefix-Print-Activity"
$description = "Applies DLP action based on the Classification levels. Will create email incident reports on documents that are labelled as 'Tender', 'Submission Qualitative' , 'Submission Commercial', 'Evaluation Qualitative', 'Evaluation Commercial', 'Strictly Confidential', and/or 'Contract Award' and print activities are performed on device"

$endpointDlpSettings = @(
    @{
        "Setting" = "Print";
        "Value"   = "Audit"
    }
)

$doesPolicyAlreadyExists = $false
foreach ($name in $dlpNames) {
    if ($name -eq $devicePrintActivityPolicyName) {
        $doesPolicyAlreadyExists = $true
        Break
    }
}

if (!$doesPolicyAlreadyExists) {
    New-DlpCompliancePolicy -Name $devicePrintActivityPolicyName -Comment $description -EndpointDlpLocation All
}

$dlpRuleNames = (Get-DlpComplianceRule).Name
$doesRuleAlreadyExists = $false
foreach ($name in $dlpRuleNames) {
    if ($name -eq $devicePrintActivityRuleName) {
        $doesRuleAlreadyExists = $true
        Break
    }
}
if (!$doesRuleAlreadyExists) {
    New-DlpComplianceRule -Name $devicePrintActivityRuleName -Policy $devicePrintActivityPolicyName  -ContentContainsSensitiveInformation $sensitivityLabels -EndpointDlpRestrictions $endpointDlpSettings  -GenerateAlert $emailToSendNotification
}

Disconnect-ExchangeOnline -Confirm:$false
