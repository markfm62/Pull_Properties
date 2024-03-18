# Pull_Properties
Utility to extract the fields from firmware /vendor/build.prop or /system/system/build.prop, or from the /system/build.prop in an active phone.  

Output files
    xxxx.txt - list of the fields pulled from the firmware
	xxxx.build.prop - the build.prop is renamed with a descriptive prefix after processing
    xxxx_MHPCstring.txt - an MHPC-module-format fingerprint string. 
    xxxx_V15_pif.json - format used in PIF V15 releases
	_prints.txt Master list of prop files that were extracted, sorted alphabetically.  I later append "BAD" or "GOOD" at the end of each line, after testing with a PI checker.  This file grows as additional build.prop are processed, 1 line per build.prop

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
NOTE:
If you don't have Powershell version 7, install it and run this script from a PS7 terminal window.
Older PS versions have an issue with writing two extra characters on the first line of a file
If you don't install powershell 7, delete the "Requires" line at the top, but you will then need to edit the
output pif.json file, remove the obvious odd characters at the very start of the file.
