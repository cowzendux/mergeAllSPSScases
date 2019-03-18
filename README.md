# mergeAllSPSScases

SPSS Python Extension function to merge all SPSS data sets in a directory by adding cases

The program will find all of the .sav files in the first directory and merge them into a single data file. It is assumed that the different files contain different observations on the same set of variables. 

This and other SPSS Python Extension functions can be found at http://www.stat-help.com/python.html

## Usage
**mergeAllSPSScases(indir, mergename, outdir, sourceVar, alignFormats)**
* "indir" is the location of the original data files.
* "mergename" is the name you want given to the merge file.
* "outdir" is an optional argument indicating where you want the merge file to be placed. If the destination directory is excluded, the program will put the merge file in a subdirectory off of the location of the original data files.  
* "sourceVar" is an optional argument indicating whether you want to include the source as a variable in the final merge file. If this argument is assigned to a string, then that string is the name of the variable that will contain the source. If this argument is omitted, then final data file will not contain a variable indicating the source.
* "alignFormats" is an optional argument indicating whether you want the to automatically convert the data sets to align the variable formats before trying to merge the data sets. This will require an extra pass through the data sets If this argument is omitted, the program will not try to align the format of the the data sets.

## Example
**mergeAllSPSScases(indir = "C:/Users/jd4nb/Dropbox/Art project/Data/Raw",  
mergename = "Merged art data.sav",  
outdir = "C:/Users/jd4nb/Dropbox/Art project/Data/Final",  
sourceVar = "School",  
alignFormats = True)**
* This program would find all of the SPSS data files in the Raw directory, merge them together and save that as a file named "Merged art data.sav" that is placed in the Final directory. 
* The final file will contain a variable named "School" that will indicate what file the each case came from. 
* The program will take the extra sets necessary to align the formats of the variables across the data sets before merging them.
