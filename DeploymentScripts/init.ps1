function DownloadDeploymentScripts()
{
Write-Host "DownloadDeploymentScripts entered"
	# The region associated with your bucket e.g. eu-west-1, us-east-1 etc. (see http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html#concepts-regions)
	$region = "us-east-1"
	# The name of your S3 Bucket
	$bucket = "coedev1-anjaneya"
	# The folder in your bucket to copy, including trailing slash. Leave blank to copy the entire bucket
	$keyPrefix = "ContosoUniversity/"
	# The local file path where files should be copied
	$localPath = "C:\"
    # AWS profile name
    $profileName = "myProfileName"

	$objects = Get-S3Object -BucketName $bucket -KeyPrefix $keyPrefix -Region $region

	foreach($object in $objects) {
		$localFileName = $object.Key -replace $keyPrefix, ''
		if ($localFileName -ne '') {
			$localFilePath = Join-Path $localPath $localFileName
			Copy-S3Object -BucketName $bucket -Key $object.Key -LocalFile $localFilePath  -Region $region
		    #Copy-S3Object -BucketName $bucket -Key $object.Key -LocalFile $localFilePath -AccessKey $accessKey -SecretKey $secretKey -Region $region
            #Copy-S3Object -BucketName $bucket -Key $object.Key -LocalFile $localFilePath  -Region $region -ProfileName $profileName
            Write-Host "File from S3 Path is  : " + $localFilePath
		}
	}
	
	
	Write-Host "DownloadDeploymentScripts exit"
}

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

function CreateAWSProfile()
{
    # Writes a new (or updates existing) profile with name "myProfileName"
    # in the encrypted SDK store file

    Set-AWSCredential -AccessKey "8888" -SecretKey "888" -StoreAs myProfileName

    # Checks the encrypted SDK credential store for the profile and then
    # falls back to the shared credentials file in the default location

    Set-AWSCredential -ProfileName myProfileName

    # Bypasses the encrypted SDK credential store and attempts to load the
    # profile from the ini-format credentials file "mycredentials" in the
    # folder C:\MyCustomPath

    Set-AWSCredential -ProfileName myProfileName -ProfileLocation C:\MyCustomPath\mycredentials
}

$launchInstance = "C:\ProgramData\Amazon\EC2-Windows\Launch\Scripts\InitializeInstance.ps1 -Schedule"
$readyInstance = "C:\ProgramData\Amazon\EC2-Windows\Launch\Scripts\SendWindowsIsReady.ps1 -Schedule"

Write-Host "before $launchInstance"

Invoke-Expression $launchInstance

Write-Host "before $readyInstance"
Invoke-Expression $readyInstance

Write-Host "Before Create AWS Profile"

# CreateAWSProfile

Write-Host "After Create AWS Profile"

Write-Host "before DownloadDeploymentScripts"

DownloadDeploymentScripts

Write-Host "after DownloadDeploymentScripts"

$deploymentScriptsZipPath = "c:\DeploymentScripts.zip"
$deploymentScriptsPath = "C:\DeploymentScripts"
$cRoot = "C:\"
$deploymentFilePath = $deploymentScriptsPath + "\deployment.ps1"
$systemSettingsFilePath = $deploymentScriptsPath + "\ApplySystemSettings.ps1"

UnZipMe -zipfilename $deploymentScriptsZipPath  -destination $cRoot

Invoke-Expression $deploymentFilePath

Invoke-Expression $systemSettingsFilePath
