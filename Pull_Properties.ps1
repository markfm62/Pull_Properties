#Requires -Version 7
<#PSScriptInfo
.VERSION 1.0.1
.AUTHOR Mark Moriarty
.COPYRIGHT 2024
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES
#>

<#
If you don't have Powershell version 7, install it and run this script from a PS7 terminal window.
Older PS versions have an issue with writing two extra characters on the first line of a file
If you don't install powershell 7, delete the "Requires" line at the top, but you will then need to edit the
output pif.json file, remove the obvious odd characters at the very start of the file.

#>
$file = 'build.prop'
<#
Utility to extract the fields needed for a pif.json file from a firmware build.prop file.

Output files
    1. xxxx.txt - list of the fields pulled from the firmware
	2. xxxx.build.prop - the build.prop is renamed with a descriptive prefix after processing
    3. xxxx_MHPCstring.txt - an MHPC-module-format fingerprint string. 
    4. xxxx_V15_pif.json - format used in PIF V15 releases
	5. _prints.txt - Master list of prop files that were extracted, sorted alphabetically. This can be used to keep a master list of usable pif.json, by later appending "BAD" or "GOOD" at the end of each line, after testing with a PI checker. This file grows as additional build.prop are processed, 1 line per build.prop

The build.prop processed is whatever is found in the script's directory
 
It should work with a build.prop pulled right from a phone (file found at /system/build.prop) or, from a factory firmware set, for the files found at /vendor/build.prop or /system/system/build.prop; for factory firmware, if it's available I've found the /vendor/build.prop file more complete than the system one.

The pif.json does not have to match your phone make and model (e.g., a OnePlus model X can pass with a Samsung model Y pif.json).

PIF only uses the json for answering a Play Integrity check across the Internet, it doesn't modify build.prop contents on your phone.

Find a place that has factory image file sets for whatever phone brand you want to try pulling fingerprints from.

Firmware with  a "security_patch_lvl" older than 2022_01_01 is best to try, firmware with a build date in 2020 or earlier.  Newer stock firmware at some point doesn't work for pif.json because Google recognizes that those fingerprints should allow hardware attestion to be used; you will fail Device.

A given pif.json may fail because it has been banned.

Download a set of factory firmware, then pull out the images that have /system and/or /vendor partitions, place the build.prop in the directory with the script, then run the script.

There are various tools to do unpacking/extracting, but I use either current 7zip, CRB Kitchen since I do some other things with it, or a slightly modified copy of sparse_converter.sh to handle Motorola sparse chunks with their special Motorola header/footer additions.

Rename a xxxx_V15__pif.json file to just pif.json, and place it in /data/adb, for PIF to use it.
 
 #>
 
$PropsList = @(".vendor.name=", ".system.name=", "ro.product.name=", ".vendor.device=", ".system.device=", "ro.product.device=", ".vendor.manufacturer=", ".system.manufacturer=",  ` 
			"ro.product.manufacturer=", ".vendor.brand=",".system.brand=",".product.brand=", ".vendor.model=", ".system.model=",".product.model=",".vendor.build.fingerprint=", ".system.build.fingerprint=", "ro.build.fingerprint=", "ro.build.thumbprint=", `
			"ro.vendor.build.security_patch=", "ro.build.version.security_patch=", `
			"ro.product.first_api_level=", ".vendor.build.id=", ".system.build.id=","ro.build.id=")

$PropsCount = 9  # Checking for both system and vendor build.prop matches, but really looking for 9 total properties

<#
 check for a build.prop in CRB kitchen, if so pull it to the script's directory
 change propLocation to wherever your build.prop file is found, or copy it manually  into the folder containing this script
 
#>

<#  Commented out - remove the comment markers for this piece if you want to use the pull-build.prop-from-somewhere capability
$propLocation = "D:\_CRBkitchen\crb_338\Projects\Extract\ROM\vendor\build.prop"
if (Test-Path -Path $propLocation) {
	$destVal = Get-Location
	$destVal = $destVal
	Copy-Item $propLocation -Destination $destVal 
   }
#>

<#
Variable initialization
 field name properties based on: https://android.googlesource.com/platform/frameworks/base/+/master/core/java/android/os/Build.java
 for example, PRODUCT comes from PRODUCT = getString("ro.product.name");, which is ro.product.vendor.name in the vendor build.prop file
#>
$MatchCount = 0  # start with no fields yet matched
$productVal = ""  # from ro.product.system.name
$deviceVal = ""
$manufacturerVal = ""
$brandVal = ""
$modelVal = ""
$fingerprintVal = ""
$thumbVal = ""
$patchVal = ""
$apiVal = ""
$idVal = ""

$FileContent = Get-Content 'build.prop'        

    foreach( $Line in $FileContent ) {  # cycle through the lines in the build.prop file
		$propertyVal =""
	   foreach( $Prop in $PropsList ) {  # for a given.prop line, check it against each of the items in $PropsList
				if ( ( $Line | Select-String $Prop -Quiet )  ) { # there's a match to one of the items in $PropsList
					$MatchCount = $MatchCount + 1 #at the end, should have MatchCount = PropsCount
					$propertyVal = $Line.Substring($Line.LastIndexOf("=") +1) # capture the property
					if ( ( $Line | Select-String ".name=" -Quiet )  ) { $productVal =  $propertyVal } 
					if ( ( $Line | Select-String ".device=" -Quiet )  ) {  $deviceVal =  $propertyVal  }
					if ( ( $Line | Select-String ".manufacturer=" -Quiet )  ) {  $manufacturerVal =  $propertyVal  }
					if ( ( $Line | Select-String ".brand=" -Quiet )  ) {  $brandVal =  $propertyVal  }
					if ( ( $Line | Select-String ".model=" -Quiet )  ) {  $modelVal =  $propertyVal  }
					if ( ( $Line | Select-String ".fingerprint=" -Quiet )  ) {  $fingerprintVal =  $propertyVal  }
					if ( ( $Line | Select-String ".thumbprint=" -Quiet )  ) {  $thumbVal =  $propertyVal  }
					if ( ( $Line | Select-String ".security_patch=" -Quiet )  ) {  $patchVal =  $propertyVal  }
					if ( ( $Line | Select-String ".first_api_level=" -Quiet )  ) {  $apiVal =  $propertyVal  }
					if ( ( $Line | Select-String ".build.id=" -Quiet )  ) {  $idVal =  $propertyVal  }
				} # if Line contains $Prop
	   } # foreach $Prop
    } # foreach $Line

# check for whether there's a thumbprint but no fingerprint
	If ($fingerprintVal -eq "" ) {  # no fingerprint
		if ($thumbVal -ne "") { # do have a thumbprint, so we'll build a fingerprint
		   $fingerprintVal = $manufacturerVal + '/' + $productVal + '/' + $deviceVal + ':' + $thumbVal
		}
	}
	# apiVal is the one parameter that's okay to fake if it wasn't found - check for that one being missing
	if ( $apiVal -eq "" ) {
			$apiVal = "null"						# 25 is the highest value that will work, but use null if the parameter isn't in build.prop
			$MatchCount = $MatchCount + 1
	}
	# Output the xxxx.txt file, including a flag  if insufficient properties found
	$textInfo = (Get-Culture).TextInfo									# used to get a leading capital
	$UCbrand = $textInfo.ToTitleCase($brandVal)			# change, for example, "samsung" to "Samsung"
	$endIndex = $fingerprintVal.IndexOf(":user/")
	$fwVal = $fingerprintVal.Substring(($endIndex -5),5)			#capture the last 5 char of the FW ro.build.version.incremental for use in file names
	# replace any "\" in fwVal by a "_" - seen in Mororola build.prop
	$fwVal = $fwVal.replace('\','_')
	$fwVal = $fwVal.replace('/','_')
	
	If ($patchVal -eq "") {  # no security_oatch value
	  $FnamePrefix = $UCbrand + "_" + $modelVal + "_" + $fwVal 	# used for the various output files
	} else {  # include the patch_level date in the name string
	  $FnamePrefix = $UCbrand + "_" + $modelVal + "_" + $patchVal + "_" + $fwVal 
	}
	# save the list of properties
	$Fname = $FnamePrefix + ".txt"
	$OutLine= "Properties = " + $PropsCount + " Matches = " + $MatchCount + "   " + $fwVal
	Write-Output "$OutLine" | Out-File -FilePath "$Fname" 
	$OutLine = 'Product=' + $productVal  + '  Device=' + $deviceVal + '  Manufacturer=' +  $manufacturerVal
	Write-Output "$OutLine" | Out-File -FilePath "$Fname" -Append
	$OutLine = 'Brand=' + $brandVal  + '  Model=' + $modelVal + '  Fingerprint=' +  $fingerprintVal
	Write-Output "$OutLine" | Out-File -FilePath "$Fname" -Append
	$OutLine = 'Security Patch=' + $patchVal  + '  First_API_Level=' + $apiVal + '  Build ID=' +  $idVal
	# apiVal has to be no greater than 25, Nougat
	if ( $apiVal -ne "null") {   # leave null alone, otherwise check the value
		if ( [int]$apiVal -gt 25 ) { $OutLine = $OutLine + '  *** For pif.json, setting FIRST_API_LEVEL to 25 ***' } 
		
		if ( [int]$apiVal -gt 25 ) { $apiVal = 25 }
	}
	Write-Output "$OutLine" | Out-File -FilePath "$Fname" -Append
    # Add a note if not all properties found
	if ($PropsCount -gt $Matchcount) {     
		$OutLine = '*** Missing required build.prop parameters - not generating MHPC or json files - check for an "=" with nothing after it ***'
		Write-Output "$OutLine" | Out-File -FilePath "$Fname" -Append
	}
 
#	 if ($PropsCount -eq $MatchCount) {    					# full set of properties found - output the MHPC and two pif.json files
		# save the MHPC format line
		$Fname = $FnamePrefix + "_MHPCstring.txt"
		$OutLine = $UCbrand + ' ' + $modelVal + ' ' + $patchVal + ' ' + $fwVal + ':' + $UCbrand + ":" + $modelVal + '=' + $fingerprintVal + '__' + $patchVal
		Write-Output "$OutLine" | Out-File -FilePath "$Fname" 

		if (-Not (Test-Path '.\_prints.txt')) {  # make sure there's a master _prints.txt file; if not, create it.
			$null = New-Item -Force '.\_prints.txt'
		}	
		Write-Output "$OutLine" | Out-File -FilePath '_prints.txt' -Append  
		gc '_prints.txt' | sort | get-unique > '_prints_sorted.txt' # sort the prints file, cull any true duplicates using get-unique
		# general format of the command to sort: gc unsorted.txt | sort | get-unique > sorted.txt
		$renVal = '.\_prints.txt'
		rm $renVal -r -fo # delete the old file
		Rename-Item -Path '.\_prints_sorted.txt' -NewName '.\_prints.txt'
<# _prints.txt note
I use this file as a scorecard, capture the results of V15 pif.json checks by adding " BAD" or " GOOD" at the end of each line.
Possible future extension could be taking _prints.txt, generating a proper MHPC prints.sh file for those lines tagged " GOOD", generate a new MHPC .zip module.
#>

		# save the pif.json	*** PIF V15 FORMAT ***
		$Fname15 = $FnamePrefix + '_V15_pif.json'
		$OutLine = '{'
		Write-Output "$OutLine" | Out-File -FilePath "$Fname15"
		$OutLine = '    "PRODUCT": "' + $productVal + '",'
		Write-Output "$OutLine" | Out-File -FilePath "$Fname15" -Append
		$OutLine = '    "DEVICE": "' + $deviceVal + '",'
		Write-Output "$OutLine" | Out-File -FilePath "$Fname15" -Append
		$OutLine = '    "MANUFACTURER": "' + $manufacturerVal + '",'
		Write-Output "$OutLine" | Out-File -FilePath "$Fname15" -Append
		$OutLine = '    "BRAND": "' + $brandVal + '",'
		Write-Output "$OutLine" | Out-File -FilePath "$Fname15" -Append
		$OutLine = '    "MODEL": "' + $modelVal + '",'
		Write-Output "$OutLine" | Out-File -FilePath "$Fname15" -Append
		$OutLine = '    "FINGERPRINT": "' + $fingerprintVal + '",'
		Write-Output "$OutLine" | Out-File -FilePath "$Fname15" -Append
		$OutLine = '    "SECURITY_PATCH": "' + $patchVal + '",'
		Write-Output "$OutLine" | Out-File -FilePath "$Fname15" -Append
		if ($apiVal -eq "null") {
		    $OutLine = '    "FIRST_API_LEVEL":"null",'
		}		  
		else {
			$OutLine = '    "FIRST_API_LEVEL": ' + $apiVal + ','
		}
		Write-Output "$OutLine" | Out-File -FilePath "$Fname15" -Append
		$OutLine = '    "ID": "' + $idVal + '"'		
		Write-Output "$OutLine" | Out-File -FilePath "$Fname15" -Append
		$OutLine = '}'
		Write-Output "$OutLine" | Out-File -FilePath "$Fname15" -Append
#	 } # if Propcount matches MatchCount
$renameVal = $FnamePrefix + '.build.prop'
$renVal = ".\" + $renameVal
<#
if (Test-Path -Path $renVal) { #delete pre-existing file
	rm  $renVal -r -fo
}
#>
Rename-Item build.prop -NewName $renameVal       # rename the build.prop with the prefix used for the other files

(Get-Item $renVal).LastWriteTime = Get-Date # update timestamp to match the other output files
