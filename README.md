# Mrwa.Teams.Procurement.Deployment
- GitHub repo for Main Roads and InSight development of Teams/SharePoint business logic automation

# Create-ProcurementTeams.ps1
- Create the following:
  - Main Roads Team
    - Standard channels
    - Private channels
    - SharePoint Online subsites including Develop
  - Contractors Team
    - Standard channels
    - Private channels
    - SharePoint Online subsites including Portal
- Populate folder structures
- Apply customisations to each SharePoint Online site
  - Set Perth time zone
  - Create Contributors group
  - Versioning to be Major and Minor
  - Documents to open in Client Application
  - Draft Item security to Only users who can edit items
  - Content Approval to Yes

 ## Usage
 e.g.
 ### Project Team
 ```
 .\Create-ProcurementTeams.ps1 -M365Domain “mainroads” -ProjectName “Canning Bus Bridge Interchange” -ProjectNumber “30001228” -ProjectAbbreviation “CBBI” -ContractType "D&C” -TeamType “Project”
```
### Contract Team
```
.\Create-ProcurementTeams.ps1 -M365Domain “mainroads” -ProjectName “Canning Bus Bridge Interchange” -ProjectNumber “30001228” -ProjectAbbreviation “CBBI” -ContractType "D&C” -TeamType “Contract”
```

# LabelAutomation.ps1
- Create labels
- Create security groups
## Usage
```
.\LabelAutomation.ps1 -servicePrincipal "c3652-adm@mainroads.wa.gov.au" -projectId "MR-30000597-MEBD-PRJ" -groupOwner "scott.white@mainroads.wa.gov.au" -domainName "group.mainroads.wa.gov.au"
```

# ProponentLabelAutomation.ps1
- Create Proponent labels
- Create security groups
## Usage
```
.\ProponentLabelAutomation.ps1 -servicePrincipal "c3652-adm@mainroads.wa.gov.au" -projectId "MR-30000597-MEBD-PRJ" -groupOwner "scott.white@mainroads.wa.gov.au" -domainName "group.mainroads.wa.gov.au"  -proponentNames "AAA,BBB,CCC"
```