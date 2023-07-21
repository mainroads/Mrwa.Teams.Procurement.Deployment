#
# This script updates M365 Groups, Sensitivity Labels, Label Policy, and DLP Policy that triggers when documents that has below defined sensitivity labels is shared outside the organization or print activity is performed on endpoint devices
#           - Tender 
#           - Submissions Qualitative
#           - Submissions Commercial 
#           - Evaluation Qualitative 
#           - Evaluation Commercial
#           - Strictly Confidential
#           - Contract Award
# Version 0.1
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
Write-Host "Updating M365 Groups..."

# Project Management
Write-Host "Updating $groupNameManagement group..."
$group = Get-UnifiedGroup -Identity $aliasManagement
$group.Owner = $groupOwner
Set-UnifiedGroup -Identity $aliasManagement -UnifiedGroup $group

# Project Support
Write-Host "Updating $groupNameSupport group..."
$group = Get-UnifiedGroup -Identity $aliasSupport
$group.Owner = $groupOwner
Set-UnifiedGroup -Identity $aliasSupport -UnifiedGroup $group

# Evaluation Team - Qualitative
Write-Host "Updating $groupNameEvalQualitative group..."
$group = Get-UnifiedGroup -Identity $aliasEvalQualitative
$group.Owner = $groupOwner
Set-UnifiedGroup -Identity $aliasEvalQualitative -UnifiedGroup $group

# Evaluation Team - Commercial
Write-Host "Updating $groupNameEvalCommercial group..."
$group = Get-UnifiedGroup -Identity $aliasEvalCommercial
$group.Owner = $groupOwner
Set-UnifiedGroup -Identity $aliasEvalCommercial -UnifiedGroup $group

# Probity
Write-Host "Updating $groupNameProbity group..."
$group = Get-UnifiedGroup -Identity $aliasProbity
$group.Owner = $groupOwner
Set-UnifiedGroup -Identity $aliasProbity -UnifiedGroup $group

# Legal
Write-Host "Updating $groupNameLegal group..."
$group = Get-UnifiedGroup -Identity $aliasLegal
$group.Owner = $groupOwner
Set-UnifiedGroup -Identity $aliasLegal -UnifiedGroup $group

# Governance
Write-Host "Updating $groupNameGovernance group..."
$group = Get-UnifiedGroup -Identity $aliasGovernance
$group.Owner = $groupOwner
Set-UnifiedGroup -Identity $aliasGovernance -UnifiedGroup $group

# Contractor
Write-Host "Updating $groupNameContractor group..."
$group = Get-UnifiedGroup -Identity $aliasContractor
$group.Owner = $groupOwner
Set-UnifiedGroup -Identity $aliasContractor -UnifiedGroup $group