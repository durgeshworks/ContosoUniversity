</pre>
function ZipMe {
 Param([string]$path)
 
if (-not $path.EndsWith('.zip')) {$path += '.zip'}
 
if (-not (test-path $path)) {
 set-content $path ("PK" + [char]5 + [char]6 + ("$([char]0)" * 18))
 }
 $ZipFile = (new-object -com shell.application).NameSpace($path)
 #$input | foreach {$zipfile.CopyHere($_.fullname, 20)}
 
foreach($file in $input)
 {
 $zipfile.CopyHere($file.FullName, 20)
 # Without this it throws errors. I'm not sure why.
 Start-sleep -milliseconds 500
 }
}
 
Function Get-PSCredential($User,$Password)
{
 $SecPass = convertto-securestring -asplaintext -string $Password -force
 $Creds = new-object System.Management.Automation.PSCredential -argumentlist $User,$SecPass
 Return $Creds
}
# Build Website
& "C:\Windows\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe" "C:\git\simple-website\simple-website.sln"
 
if(Test-Path "c:\Admin.zip") {
 # Delete Existing zip file
 Remove-Item "c:\Admin.zip" -Force
}
 
# Zip Website
dir "C:\git\simple-website\AdminSite\" | ZipMe c:\Admin.zip
 
$credential = Get-PSCredential -User "someuser" -Password "secretpassword"
 
$session = New-PSSession 192.168.1.68 -Credential $credential
 
#Remove file if it exists
invoke-command -session $session -scriptblock {
 
if(Test-Path "c:\Admin.zip") {
 # Delete Existing zip file
 Remove-Item "c:\Admin.zip" -Force
}
}
 
Import-Module BitsTransfer
Start-BitsTransfer -source C:\Admin.zip -destination \\192.168.1.68\c$\ -credential $credential
 
invoke-command -session $session -scriptblock {
 
Set-ExecutionPolicy RemoteSigned
 
function UnZipMe($zipfilename, $destination)
{
 $shellApplication = new-object -com shell.application
 $zipPackage = $shellApplication.NameSpace($zipfilename)
 $destinationFolder = $shellApplication.NameSpace($destination)
 
# CopyHere vOptions Flag # 4 - Do not display a progress dialog box.
# 16 - Respond with "Yes to All" for any dialog box that is displayed.
 
$destinationFolder.CopyHere($zipPackage.Items(),20)
}
# Install IIS if required
Import-Module Servermanager
 
$check = Get-WindowsFeature | Where-Object {$_.Name -eq "web-server"}
 
If (!($check.Installed)) {
 Write-Host "Adding web-server"
 Add-WindowsFeature web-server
}
 
$name = "Admin"
$physicalPath = "C:\inetpub\wwwroot\" + $name
 
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
 New-WebSite $name | Out-Null
 New-WebApplication -Site $name -Name $name -PhysicalPath "C:\inetpub\wwwroot\Admin" -ApplicationPool $name
}
 
UnZipMe -zipfilename "c:\Admin.zip" -destination "C:\inetpub\wwwroot\Admin"
 
}
 
Remove-PSSession $session