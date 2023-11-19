function ConvertDicom
{
	[CmdletBinding()]
	Param([Parameter(Mandatory=$true, Position=0)]
		[string]$rice,
		[Parameter(Mandatory=$true, Position=1)]
		[string]$DICOM
	)
	cmd.exe /c "Tool_Dcff.exe" -i $rice -E
	cmd.exe /c "Tool_Dicom.exe" -i $rice -o $DICOM
	
}

$dcmExt = ".dcm";
$thisFolder = "C:\temp\joris";


$fileList = $(Get-ChildItem $thisFolder -Recurse -Include *.img);
ForEach ( $fileIn in $fileList.FullName ) {
	New-Item -ItemType "directory" -Name "DICOM" -Path $thisfolder -ErrorAction SilentlyContinue;

	$filePath = $(Split-Path -Path $fileIn -Parent -Resolve);
	$file = $(Split-Path -Path $fileIn -Leaf -Resolve);
	$fileOut = $thisFolder + "\DICOM\" + $file.split(".")[0] + $dcmExt;
	ConvertDicom $fileIn $fileOut;
	
	Move-Item $filePath\*.dcm $thisFolder\DICOM -ErrorAction SilentlyContinue;
}

# Compression with 7zip
if (Test-Path 'C:\Program Files\7-Zip')
{
	cd "C:\Program Files\7-Zip";
    7z a $thisFolder\DICOM-$(hostname).7z -r $thisFolder\DICOM -mx9 -v100m;
	Write-Host "Folder $thisFolder\DICOM has been compressed and can be found here: $thisFolder\DICOM-$(hostname).7z"
}

cd $thisFolder\..;
Get-ChildItem;