### Execution Instructions ### 
# 1. Browse to the project directory
#     cd "<project_location_in_file_system>\.Mrwa.Teams.Procurement.Deployment"
# 2. Execute Create-ProcurementTeams.ps1
#     Syntax: .\Apply-Documents_LibraryConfigurationForReviewFlow.ps1 -TargetSiteURL "<siteurl>" 
#

Param(
  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [string] $TargetSiteURL,

  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [string] $TemplaleFilePath ="$PSScriptRoot\Templates\DocumentLibraryConfiguration_Review_PowerAutomateFlow.xml"

)


Function ApplyDocumentLibrarySettingsandConfiguration-ReviewFlow

($TargetSiteURL,$TemplaleFilePath ="$PSScriptRoot\Templates\DocumentLibraryConfiguration_Review_PowerAutomateFlow.xml")
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