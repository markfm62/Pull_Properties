# Pull_Properties
Utility to extract the fields from firmware /vendor/build.prop or /system/system/build.prop, or from the /system/build.prop in an active phone.  

Output files
    xxxx.txt - list of the fields pulled from the firmware
	xxxx.build.prop - the build.prop is renamed with a descriptive prefix after processing
    xxxx_MHPCstring.txt - an MHPC-module-format fingerprint string. 
    xxxx_V15_pif.json - format used in PIF V15 releases
	_prints.txt Master list of prop files that were extracted, sorted alphabetically.  I later append "BAD" or "GOOD" at the end of each line, after testing with a PI checker.  This file grows as additional build.prop are processed, 1 line per build.prop

Read the script header comment sections for description of its usage.
 
NOTE:
If you don't have Powershell version 7, install it and run this script from a PS7 terminal window.
Older PS versions have an issue (known bug) with writing two extra characters on the first line of a file
If you don't install powershell 7, delete the "Requires" line at the top, but you will then need to edit the
output pif.json file, remove the obvious odd characters at the very start of the file.
