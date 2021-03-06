 
function UnZipMe($zipfilename, $destination)
{
	Write-Host "UnZipMe entered"
	 $shellApplication = new-object -com shell.application
	 $zipPackage = $shellApplication.NameSpace($zipfilename)

	 	 #set the destination directory for the extracts
	if (!(Test-Path $destination)) { 
    	mkdir $destination		}
	 $destinationFolder = $shellApplication.NameSpace($destination)
	 
	# CopyHere vOptions Flag # 4 - Do not display a progress dialog box.
	# 16 - Respond with "Yes to All" for any dialog box that is displayed.	 
	$destinationFolder.CopyHere($zipPackage.Items(),16)
	Write-Host "UnZipMe exit"
}
# Install IIS if required
Import-Module Servermanager
 
$check = Get-WindowsFeature | Where-Object {$_.Name -eq "web-server"}
 
If (!($check.Installed)) {
 Write-Host "Adding web-server"
 #Add-WindowsFeature web-server
 install-windowsfeature web-server, web-webserver -IncludeAllSubFeature
 install-windowsfeature web-mgmt-tools
}
 
$name = "ContosoUniversity"
$iisRootPath = "C:\inetpub\wwwroot\"
$physicalPath =  $iisRootPath + $name
$applicationZipPath = "c:\" + $name + ".zip"

 
  Write-Host "physical path : " + $physicalPath

# Create Application Pool
try
{
 $poolCreated = Get-WebAppPoolState $name –errorvariable myerrorvariable
 Write-Host $name "Already Exists"
}
catch
{
 # Assume it doesn't exist. Create it.
 New-WebAppPool -Name $name
 Set-ItemProperty IIS:\AppPools\$name managedRuntimeVersion v4.0
}
 
# Create Folder for the website
if(!(Test-Path $physicalPath)) {
 md $physicalPath
}
else {
 Remove-Item "$physicalPath\*" -recurse -Force
}
 
$site = Get-WebSite | where { $_.Name -eq $name }
if($site -eq $null)
{
 Write-Host "Creating site: $name $physicalPath"
 
 # TODO:
 New-WebSite -Name $name  -Port 81 -PhysicalPath $physicalPath -ApplicationPool $name | Out-Null
  Write-Host "Creating application: $name $physicalPath"
 New-WebApplication -Site $name -Name $name -PhysicalPath $physicalPath -ApplicationPool $name
}

$deplotmentScriptsPath = "C:\DeploymentScripts"
$unlockIISHandlersPath = $deplotmentScriptsPath + "\UnlockIISHandlers.ps1"



#UnZipMe -zipfilename $applicationZipPath -destination $iisRootPath 

#$unzippedapplicationPackage = $iisRootPath + $name + "\Content\C_C\Works\ContosoUniversity\ContosoUniversity\obj\Release\Package\PackageTmp"


UnZipMe -zipfilename $applicationZipPath -destination $iisRootPath 

$unzippedapplicationPackage = $iisRootPath + "\Content\C_C\Works\ContosoUniversity\ContosoUniversity\obj\Release\Package\PackageTmp"

Get-ChildItem $unzippedapplicationPackage | Copy -Destination $physicalPath -Recurse -filter *.*

Invoke-Expression $unlockIISHandlersPath
