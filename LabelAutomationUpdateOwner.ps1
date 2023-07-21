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
Add-UnifiedGroupLinks -Identity $aliasManagement -LinkType "Members" -Links $groupOwner
Add-UnifiedGroupLinks -Identity $aliasManagement -LinkType "Owners" -Links $groupOwner

# Project Support
Write-Host "Updating $groupNameSupport group..."
Add-UnifiedGroupLinks -Identity $aliasSupport -LinkType "Members" -Links $groupOwner
Add-UnifiedGroupLinks -Identity $aliasSupport -LinkType "Owners" -Links $groupOwner

# Evaluation Team - Qualitative
Write-Host "Updating $groupNameEvalQualitative group..."
Add-UnifiedGroupLinks -Identity $aliasEvalQualitative -LinkType "Members" -Links $groupOwner
Add-UnifiedGroupLinks -Identity $aliasEvalQualitative -LinkType "Owners" -Links $groupOwner

# Evaluation Team - Commercial
Write-Host "Updating $groupNameEvalCommercial group..."
Add-UnifiedGroupLinks -Identity $aliasEvalCommercial -LinkType "Members" -Links $groupOwner
Add-UnifiedGroupLinks -Identity $aliasEvalCommercial -LinkType "Owners" -Links $groupOwner

# Probity
Write-Host "Updating $groupNameProbity group..."
Add-UnifiedGroupLinks -Identity $aliasProbity -LinkType "Members" -Links $groupOwner
Add-UnifiedGroupLinks -Identity $aliasProbity -LinkType "Owners" -Links $groupOwner

# Legal
Write-Host "Updating $groupNameLegal group..."
Add-UnifiedGroupLinks -Identity $aliasLegal -LinkType "Members" -Links $groupOwner
Add-UnifiedGroupLinks -Identity $aliasLegal -LinkType "Owners" -Links $groupOwner

# Governance
Write-Host "Updating $groupNameGovernance group..."
Add-UnifiedGroupLinks -Identity $aliasGovernance -LinkType "Members" -Links $groupOwner
Add-UnifiedGroupLinks -Identity $aliasGovernance -LinkType "Owners" -Links $groupOwner

# Contractor
Write-Host "Updating $groupNameContractor group..."
Add-UnifiedGroupLinks -Identity $aliasContractor -LinkType "Members" -Links $groupOwner
Add-UnifiedGroupLinks -Identity $aliasContractor -LinkType "Owners" -Links $groupOwner

# Disconnect Exchange Online
Disconnect-ExchangeOnline -Confirm:$False