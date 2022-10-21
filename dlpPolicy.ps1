#
# This script provisions DLP Policy to trigger notification when documents with following sensitivity labels are shared outside the organization
#           - Tender 
#           - Submissions Qualitative
#           - Submissions Commercial 
#           - Evaluation Qualitative 
#           - Evaluation Commercial
#           - Strictly Confidential
#           - Contract Award
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


$policyName = "$prefix-DLP-Policy-IDDP"
$ruleName = "$prefix-SendNotificationWhenSharedToExternalUsers"

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

New-DlpCompliancePolicy -Name $policyName -Comment "This is a test policy comment" -SharePointLocation All -ExchangeLocation All -Mode Disable
New-DlpComplianceRule -Name $ruleName -Policy $policyName -AccessScope NotInOrganization -ContentContainsSensitiveInformation $sensitivityLabels -GenerateIncidentReport $generateIncidentReport -IncidentReportContent $incidentReportContent

Disconnect-ExchangeOnline -Confirm:$false
