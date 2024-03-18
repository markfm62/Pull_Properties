# Pull_Properties
pull_properities.ps1 is a utility to extract the fields needed for a pif.json file from a firmware build.prop file.  

Output files:
1. xxxx.txt - list of the fields pulled from the firmware
2. xxxx.build.prop - the build.prop is renamed with a descriptive prefix after processing
3. xxxx_MHPCstring.txt - an MHPC-module-format fingerprint string. 
4. xxxx_V15_pif.json - format used in PIF V15 releases
5. _prints.txt - Master list of prop files that were extracted, sorted alphabetically. This can be used to keep a master list of usable pif.json, by later appending "BAD" or "GOOD" at the end of each line, after testing with a PI checker. This file grows as additional build.prop are processed, 1 line per build.prop

Read the script header comment sections for description of its usage.
 
NOTE:
If you don't have Powershell version 7, install it and run this script from a PS7 terminal window. Older PS versions have an issue (known bug) with writing two extra characters on the first line of a file. If you don't install powershell 7, delete the "Requires" line at the top, but you will then need to edit the output pif.json file, remove the obvious odd characters at the very start of the file.
