# Define input root folder
$rootFolder = Split-Path -Parent $MyInvocation.MyCommand.Path

# Define files and folders to include in the zip file
$files = @(
    "ApplyDocumentsLibraryConfigForReviewFlow.ps1",
    "Create-ProcurementTeams.ps1",
    "LabelAutomation.ps1",
    "ProponentLabelAutomation.ps1"
)
$folders = @(
    "Seed",
    "Templates"
)

# Define zip file name
$version = "1.0.0-beta5patch1"
$zipFileName = "MWS-v$version.zip"

# Compress files and folders to zip file
Compress-Archive -Path @($files + $folders | ForEach-Object { Join-Path $rootFolder $_ }) -DestinationPath (Join-Path $rootFolder $zipFileName)
