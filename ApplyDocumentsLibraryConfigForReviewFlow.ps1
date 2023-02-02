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
  [string] $TemplaleFilePath ="$PSScriptRoot\Templates\DocumentLibraryConfigReview.xml"

)


Function ApplyDocumentLibrarySettingsandConfiguration-ReviewFlow

($TargetSiteURL,$TemplaleFilePath ="$PSScriptRoot\Templates\DocumentLibraryConfigReview.xml")
{
if($TargetSiteURL -ne "")
{
    Write-Host "Applying $TargetSiteURL required library settings from $TemplaleFilePath" -f Yellow 
  

    $TemplaleFilePath 
    if((Test-Path -Path $TemplaleFilePath -PathType Leaf) -eq $false)
    {
        write-host "File does not exist!" -ForegroundColor Red
    }
    else
    {
    #$TargetSiteURL=$TargetSiteURL +"/"
    #$TargetSiteURL=$TargetSiteURL.Replace("teams","sites")
    Connect-PnPOnline $TargetSiteURL -Interactive 

    Invoke-PnPSiteTemplate -Path $TemplaleFilePath 
    }
}

}


#$TargetSiteURL ="https://0v1sr.sharepoint.com/sites/mr-0003-prj3-prj/"
#$TemplaleFilePath ="C:\Work\MainRoad\JSON\Pnp-ProvitioningFileV33.xml" #"C:\Work\MainRoad\pnpprvitioning\Pnp-ProvitioningFileV4.xml"
ApplyDocumentLibrarySettingsandConfiguration-ReviewFlow -TargetSiteURL $TargetSiteURL -TemplaleFilePath $TemplaleFilePath