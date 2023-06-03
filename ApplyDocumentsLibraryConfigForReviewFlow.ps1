### Execution Instructions ### 
# 1. Browse to the project directory
#     cd "<project_location_in_file_system>\.Mrwa.Teams.Procurement.Deployment"
# 2. Execute Create-ProcurementTeams.ps1
#     Syntax: .\ApplyDocumentsLibraryConfigForReviewFlow.ps1 -TargetSiteURL "https://mainroads.sharepoint.com/teams/MR-30000597-MEBD-PRJ-Procurement" 
#

Param(
  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [string] $TargetSiteURL,

  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [string] $TemplateFilePath
)

if (-not $PSBoundParameters.ContainsKey('TemplateFilePath')) {
  $TemplateFilePath = Join-Path $PSScriptRoot "Templates" "DocumentLibraryConfigReview.xml"
}
Function ApplyConfig {
  param(
    [Parameter(Mandatory = $true)]
    [string]$TargetSiteURL,
    [Parameter(Mandatory = $false)]
    [string]$TemplateFilePath = (Join-Path $PSScriptRoot "Templates" "DocumentLibraryConfigReview.xml")
  )

  if ($TargetSiteURL -ne "") {

    Connect-PnPOnline -Url $TargetSiteURL -Interactive 
    $objSite = Get-PnPWeb -ErrorAction SilentlyContinue
  
    if ($objSite -eq $null) {
      if ($spUrlType -eq "teams") {
        $TargetSiteURL = $TargetSiteURL -replace "/teams/", "/sites/"
      }
      else {
        $TargetSiteURL = $TargetSiteURL -replace "/sites/", "/teams/"                     
      }
    }

    Write-Host "Applying $TargetSiteURL required library settings from $TemplateFilePath" -ForegroundColor Yellow 

    if ((Test-Path -Path $TemplateFilePath -PathType Leaf) -eq $false) {
      write-host "File does not exist!" -ForegroundColor Red
    }
    else {
      Connect-PnPOnline $TargetSiteURL -Interactive 
      Invoke-PnPSiteTemplate -Path $TemplateFilePath 
    }
  }
}

ApplyConfig -TargetSiteURL $TargetSiteURL -TemplateFilePath $TemplateFilePath