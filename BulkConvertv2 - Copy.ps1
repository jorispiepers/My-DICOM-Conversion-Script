<# Syntax: Script does bulk conversion for rice to DICOM

   Instructions:
   Make sure to enter your path in the $folder argument where the
   top image folder resides, for instance: C:\temp\image-folder-123456
   The script will then try to scoure the folder image-folder and
   the sub- folders for all image (.img) files.

   Script v0.33 created by Joris Piepers on 01-03-2022
   Added some script verbosity on the function uses
   Fixed some errors #>

# This is our target folder
$folder = "c:\temp\joris";

# Conversion to dicom with dcm ext
$dcmExt = ".dcm";

# Header ext
$hdrExt = ".hdr";

# Search for images with type .img
$image = "*.img";

<# The convertDicom function will turn all .img files into .dcm
   by running Tool_Dcff which subsequentally runs Tool_Dicom.
   Therefore it is possible that one of two executables will fail
   on your DICOM file, this is normal and expected #>
function ConvertDicom
{
	[CmdletBinding()]
	Param([Parameter(Mandatory=$true, Position=0)]
		[string]$fileIn,
		[Parameter(Mandatory=$true, Position=1)]
		[string]$fileOut
	)
	if (cmd.exe /c "Tool_Dcff.exe" -i $fileIn -E)
	{
		#Write-Host "Conversion $fileOut, successful.";
	}
	else
	{
		#Write-Host "Conversion $fileOut, failed!";
	}
	
	if (cmd.exe /c "Tool_Dicom.exe" -i $fileIn -o $fileOut)
	{
		#Write-Host "Conversion $fileOut, successful.";
	}
	else
	{
		#Write-Host "Conversion $fileOut, failed!";
	}
	
}

<# The ConvertHeader function will extract the header files from the
   Rice image file and it will transform it into a generic text file #>
function ConvertHeader
{
	[CmdletBinding()]
	Param([Parameter(Mandatory=$true, Position=0)]
		[string]$fileIn
	)

	# For use of execution for d3print
	$folder = "C:\PROGRA~1\CAREST~1\System5\utils";
	$orig = pwd;
	
    if (Test-Path -Path $folder) {
        Write-Host "Yes!";
	    #cd $folder;
        d3print.exe -i $orig.Path\$fileIn -T -O | Select-String -Pattern "Study Instance";
	    #cmd.exe /c "$folder\d3print.exe" -i $orig.Path\$fileIn -T -O #| Select-String -Pattern "Accession";
        #cmd.exe /c "$folder\3dprint.exe" -i $orig.Path\$fileIn -T -O #| Select-String -Pattern "Modality";
	    #cd $orig.path;
    }
}

function DICOM()
{
    $pwd = pwd;
    $total = Get-ChildItem . | Where-Object { $_.Name -match "DICOM" } |
    	%{$f=$_; Get-ChildItem -r $_.FullName |
    	Measure-Object -Property Length -Sum |
    		Select-Object @{Name="Name"; Expression={$f}}, @{Name="Bytes"; Expression={"{0:0}" -f ($_.sum) }}}
    #$total
    $folder = pwd;
    Write-Host "Total size for DICOM files in path $folder\DICOM :" ($total | Measure-Object -Property Bytes -Sum).sum "bytes.";

    # Compression with 7zip
    #.\7z.exe a DICOM-Dreux.7z -r .\508885\DICOM\ -mx9;
}

function Rice()
{
    $pwd = pwd;
    $total = Get-ChildItem .\ | Where-Object { $_.Name -notmatch "DICOM|.hcff" } |
    	%{$f=$_; Get-ChildItem -r $_.FullName |
    	Measure-Object -Property Length -Sum |
    		Select-Object @{Name="Name"; Expression={$f}}, @{Name="Bytes"; Expression={"{0:0}" -f ($_.sum) }}}
    #$total
    $folder = pwd;
    Write-Host "Total size for Rice files in path $folder :" ($total | Measure-Object -Property Bytes -Sum).sum "bytes.";
}

function convert([string]$folder, [string]$image)
{
	# Remove trailing slash from path
	if ($folder -match '\\$')
	{
		Write-Host "Removing trailing slash from path."
		$folder = $folder.Substring(0,$folder.Length-1)
	}
	
	Write-Host "Entering root level: $folder"
	$fileList1 = (Get-ChildItem $folder\$image);
	if ($fileList1.Name)
	{
        if (![System.IO.Directory]::Exists("$folder\DICOM"))
        {
            New-Item -ItemType "directory" -Name "DICOM" -Path $folder;
        }
		Foreach ($file in $fileList1.Name)
		{
			$fileIn = $folder + "\" + $file;
			$fileOut = $folder + "\" + $file.split(".")[0] + $dcmExt;

			ConvertDicom $fileIn $fileOut;

			#$fileOut = $folder + "\" + $file.split(".")[0] + $hdrExt;
			#ConvertHeader $fileIn $fileOut;
		}
        mv $folder\*.dcm DICOM;
	}
	else
	{
		Write-Host "Entering sub level 1: $subDir1";
		$subDirList1 = (Get-Childitem -Directory $folder);
		if ($subDirList1.Name)
		{
			Foreach ($subDir1 in $subDirList1.Name)
			{
				$fileList2 = (Get-ChildItem $folder\$subDir1\*.img);
				if ($fileList2.Name)
				{
                    if (![System.IO.Directory]::Exists("$folder\DICOM"))
                    {
         				New-Item -ItemType "directory" -Name "DICOM" -Path $folder;
                    }
					Foreach ($file in $fileList2.Name)
					{
						$fileIn = $folder + "\" + $subDir1 + "\" + $file;
		            	$fileOut = $folder + "\" + $subDir1 + "\" + $file.split(".")[0] + $dcmExt;

		            	ConvertDicom $fileIn $fileOut;

						#$fileOut = $folder + "\" + $subDir1 + "\" + $file.split(".")[0] + $hdrExt;
						#ConvertHeader $fileIn $fileOut;
					}
                    Move-Item $folder\$subDir1\*.dcm $folder\DICOM;
				}
				else
				{
					Write-Host "Entering sub level 2: $subDir2";
					$subDirList2 = (Get-Childitem -Directory $folder\$subDir1);
					if ($subDirList2.Name)
					{
						Foreach ($subDir2 in $subDirList2.Name)
						{
							$fileList3 = (Get-ChildItem $folder\$subDir1\$subDir2\*.img);
							if ($fileList3.Name)
							{
                                if (![System.IO.Directory]::Exists("$folder\$subDir1\DICOM"))
                                {
                                    New-Item -ItemType "directory" -Name "DICOM" -Path $folder\$subDir1;
                                }
                            	Foreach ($file in $fileList3.Name)
                            	{
                            		$fileIn = $folder + "\" + $subDir1 + "\" + $subDir2 + "\" + $file;
                            		$fileOut = $folder + "\" + $subDir1 + "\" + $subDir2 + "\" + $file.split(".")[0] + $dcmExt;
                        
                                    ConvertDicom $fileIn $fileOut;
                        
                            		#$fileOut = $folder + "\" + $subDir1 + "\" + $subDir2 + "\" + $file.split(".")[0] + $hdrExt;
                            		#convertHeader $fileIn $fileOut;
                            	}
                                Move-Item $folder\$subDir1\$subDir2\*.dcm $folder\$subDir1\DICOM;
                            }
						}
					}
				}
			}
		}
	}
}

# Call our main function
convert $folder $image;
cd $folder;

# Optionally list all DICOM directories and RICE folders for comparison
Clear-Host;
$list = (Get-ChildItem -Directory $folder);
Foreach ($item in $list.Name)
{
    cd $item;
    DICOM;
    Rice;
    cd ..;
}