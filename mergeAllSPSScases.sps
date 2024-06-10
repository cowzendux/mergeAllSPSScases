* Encoding: UTF-8.
* Merge all SPSS files - add cases
* By Jamie DeCoster

* This program requires a directory as the first argument, a filename
* as the second argument, and will optionally take a second directory
* as the third argument.  The program will find all of the.SPSS files 
* in the first directory and merge them into a file with a name 
* determined by the second argument. It is assumed that the 
* different files contain different observations on the same set of
* variables. The merge file is placed in the directory listed as the
* third argument if it is given. If it is omitted, it will create a 
* directory "MERGED" off of the source directory and put the 
* merge file there.

****
* Usage: mergeAllSPSScases(indir, mergename, outdir, sourceVar,
alignFormats)
****
**** "indir" is the location of the original data files
**** "mergename" is the name you want given to the merge file
**** "outdir" is an optional argument indicating where you want 
* the merge file to be placed. If the destination directory is excluded, 
* the program will put the merge file in a subdirectory off of the location of the
* original data files.  
**** "sourceVar" is an optional argument indicating whether you want
* to include the source as a variable in the final merge file. If this argument is
* assigned to a string, then that string is the name of the variable that will
* contain the source. If this argument is omitted, then final data file will not
* contain a variable indicating the source.
**** "alignFormats" is an optional argument indicating whether you want the to 
* automatically convert the data sets to align the variable formats before trying
* to merge the data sets. This will require an extra pass through the data
* sets If this argument is omitted, the program will not try to align the format 
* of the the data sets.

*****
* Example
*****
* mergeAllSPSScases(indir = "C:/Users/jd4nb/Dropbox/Art project/Data/Raw",
mergename = "Merged art data.sav",
outdir = "C:/Users/jd4nb/Dropbox/Art project/Data/Final",
sourceVar = "School",
alignFormats = True)
* This program would find all of the SPSS data files in the Raw directory,
* merge them together and save that as a file named "Merged art data.sav"
* in the Final directory. The final file will contain a variable named "School"
* that will indicate what file the each case came from. The program will
* take the extra sets necessary to align the formats of the variables across
* the data sets before merging them.

set printback = off.

begin program python3.
import spss, os, re

def mergeAllSPSScases(indir, mergename, outdir = "NONE", 
                      sourceVar = False, alignFormats = False):

    # Strip / at the end of files if it is present
    for dir in [indir, outdir]:
        if (dir[len(dir)-1] == "/"):
            dir = dir[:len(dir)-1]

    if (mergename[-4:] == ".sav"):
    # Strip .sav at the end of merge file if it is present
        mergename = mergename[:-4]

    # If outdir is excluded, create output directory if it doesn't exist
    if outdir == "NONE":
        if not os.path.exists(indir + "/MERGED"):
            os.mkdir(indir + "/MERGED")
        outdir = indir + "/MERGED"

    # Get a list of all .sav files in the directory (spssfiles)
    allfiles=[os.path.normcase(f)
              for f in os.listdir(indir)]
    spssfiles=[]
    for f in allfiles:
        fname, fext = os.path.splitext(f)
        if ('.sav' == fext):
            spssfiles.append(fname)

    submitstring = """new file.
dataset name $dataset window=front."""
    spss.Submit(submitstring)

    #####
    # Merge files without converting formats
    #####

    if (alignFormats == False):
        submitstring = """GET
FILE='%s/%s.sav'.
DATASET NAME $DataSet WINDOW=FRONT.""" %(indir, spssfiles[0])
        spss.Submit(submitstring)
        count = 0
        for f in spssfiles[1:]:
            count += 1
            submitstring = "ADD FILES /file=*"
            submitstring += """/n/file='%s/%s.sav'
/in=s7663804s%s""" %(indir, f, count)
            submitstring += """.
EXECUTE."""
            spss.Submit(submitstring)

        # Create source variable
        if (sourceVar != False):
            submitstring = """string %s (a%s).
    do if (s7663804s1=0""" %(sourceVar, max(len(str(x)) for x in spssfiles)+1)
            for f in range(len(spssfiles)-2):
                submitstring += "/n and s7663804s"+ str(f+2) + "=0"
                submitstring += """).
        compute %s = '%s'.
        end if.""" %(sourceVar, spssfiles[0])
                for f in range(len(spssfiles)-1):
                    submitstring += "/nif (s7663804s%s=1) %s = '%s'." %(str(f+1), 
                                                                        sourceVar, spssfiles[f+1])
                submitstring += "/nexecute."
                spss.Submit(submitstring)

                submitstring = "delete variables"
                for f in range(len(spssfiles)-1):
                    submitstring += "/ns7663804s" + str(f+1)
                submitstring += "."
                spss.Submit(submitstring)

    #####
    # Merge files while converting formats
    #####

    # Determine largest size for each variable
    if (alignFormats == True):
        varNames = []
        varType = []
        varLength = []
        varDec = []
        typeDict = {"DATETIME":1, "DATE" : 2, "TIME" : 3,
                    "F" : 4, "A" : 5}
        for f in spssfiles:
            submitstring = """GET
FILE='%s/%s.sav'.
DATASET NAME $DataSet WINDOW=FRONT.""" %(indir, f)
            spss.Submit(submitstring)
            for t in range(spss.GetVariableCount()):
                if (spss.GetVariableName(t) not in varNames):
                    varNames.append(spss.GetVariableName(t))
                    varType.append("DATETIME")
                    varLength.append(0)
                    varDec.append(0)
                for i in range(len(varNames)):
                    if (spss.GetVariableName(t) == varNames[i]):
                        f = spss.GetVariableFormat(t)
                        d = re.search("\d", f)
                        p = f.find(".")
                        type = f[:d.start()]
                        if (p > 0):
                            size = int(f[d.start():p])
                            dec = int(f[p+1:])
                        else:
                            size = int(f[d.start():])
                            dec = 0
                        if (typeDict[type] > typeDict[varType[i]]):
                            varType[i] = type
                        if (size > varLength[i]):
                            varLength[i] = size
                        if (dec > varDec[i]):
                            varDec[i] = dec
        alterList = []
        for t in range(len(varNames)):
            if (varType[t] == "DATE" or varType[t] == "A"):
                varDec[t] = 0
            if (varDec[t] == 0):
                alterList.append("alter type {0} ({1}{2}).".format(varNames[t], 
varType[t], varLength[t]))
            else:
                alterList.append("alter type {0} ({1}{2}.{3}).".format(varNames[t], 
varType[t], varLength[t], varDec[t]))

        # Merging files
        count = 0
        for f in spssfiles:
            count += 1
            submitstring = """GET
FILE='%s/%s.sav'.
DATASET NAME infile WINDOW=FRONT.""" %(indir, f)
            spss.Submit(submitstring)
            # Convert variable formats
            varList = []
            for t in range(spss.GetVariableCount()):
                varList.append((spss.GetVariableName(t).upper()))
            for t in range(len(varNames)):
                if (varNames[t].upper() in varList):
                    submitstring = alterList[t]
                    spss.Submit(submitstring)
            # Create source variable
            if (sourceVar != False):
                submitstring = """string %s (a%s).
compute  %s = '%s'.
execute.""" %(sourceVar, max(len(str(x)) for x in spssfiles)+1,
sourceVar, f)
                spss.Submit(submitstring)
            # Merge with other files
            if (count == 1):
                submitstring = "dataset name $dataset."
                spss.Submit(submitstring)
            else:
                submitstring = """dataset activate $dataset.
ADD FILES /FILE=*
/FILE='infile'.
execute.""".format(count)
                spss.Submit(submitstring)

        submitstring = "dataset close infile."
        spss.Submit(submitstring)

    # Save file
    submitstring = """SAVE OUTFILE='%s/%s.sav'
/COMPRESSED.""" %(outdir, mergename)
    spss.Submit(submitstring)
end program python3.
set printback = on.

**********
* Version History
**********
* 2013-06-08 Created
* 2013-06-09 Merged and saved files
* 2013-07-30 Used separate merge commands for each file
* 2013-09-11 Fixed error when removing .sav at the end of mergename
* 2013-09-30 Added sourceVar option
* 2014-06-17 Added toggle to automatically align variable formats
* 2014-06-18 Continued work on automatically aligning variable formats
* 2015-07-26 Removed + symbol in front of looped commands
* 2019-03-08 Works on datetime and time types
* 2023-06-28 Updated to Python3
