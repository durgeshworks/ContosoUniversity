# Your account access key - must have read access to your S3 Bucket
$accessKey = "YOUR-ACCESS-KEY"
# Your account secret access key
$secretKey = "YOUR-SECRET-KEY"
# The region associated with your bucket e.g. eu-west-1, us-east-1 etc. (see http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html#concepts-regions)
$region = "eu-west-1"
# The name of your S3 Bucket
$bucket = "my-test-bucket"
# The folder in your bucket to copy, including trailing slash. Leave blank to copy the entire bucket
$keyPrefix = "my-folder/"
# The local file path where files should be copied
$localPath = "C:\s3-downloads\"

$objects = Get-S3Object -BucketName $bucket -KeyPrefix $keyPrefix -AccessKey $accessKey -SecretKey $secretKey -Region $region

foreach($object in $objects) {
	$localFileName = $object.Key -replace $keyPrefix, ''
	if ($localFileName -ne '') {
		$localFilePath = Join-Path $localPath $localFileName
		Copy-S3Object -BucketName $bucket -Key $object.Key -LocalFile $localFilePath -AccessKey $accessKey -SecretKey $secretKey -Region $region
	}
}