Function ApplyDocumentLibrarySettingsandConfiguration-ReviewFlow($TargetSiteURL,$TemplaleFilePath ="$PSScriptRoot\Templates\DocumentLibraryConfiguration_Review_PowerAutomateFlow.xml")
{

$TemplaleFilePath #=& "$PSScriptRoot\Templates\DocumentLibraryConfiguration_Review_PowerAutomateFlow.xml"
if((Test-Path -Path $TemplaleFilePath -PathType Leaf) -eq $false)
{
    write-host "File does not exist!" -ForegroundColor Red
}

#$TargetSiteURL=$TargetSiteURL.Replace("teams","sites")
Connect-PnPOnline $TargetSiteURL -Interactive 

Invoke-PnPSiteTemplate -Path $TemplaleFilePath 

}



#$TargetSiteURL ="https://0v1sr.sharepoint.com/sites/mr-0003-prj3-prj/"
#$TemplaleFilePath ="C:\Work\MainRoad\JSON\Pnp-ProvitioningFileV33.xml" #"C:\Work\MainRoad\pnpprvitioning\Pnp-ProvitioningFileV4.xml"
#ApplyDocumentLibrarySettingsandConfiguration-ReviewFlow $TargetSiteURL #$TemplaleFilePath