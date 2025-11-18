#!/bin/bash
<<README
This script is deleting data, which is older than 180 days, from the $DUMPDIR  

This script is part of the janitor-job

mode of function:
- find in $DUMPDIR all files older than 180 days and remove them.
- find in $DUMPDIR all empty folders (relicts of cleanup) and remove them.
README
#fsdb-rev-date: 251015

# get location of this script
thisDir=$(dirname $(realpath "$0"))

# find and source getVar.sh to set all global variables
source getVar
intro $(basename $0)

#debug=2

## clean dump; 
# remove everything older than 0.5 year from dump. 
find $DUMPDIR -mtime +180 -delete >>$LOG 2>&1
# remove left-over (empty) folders
find $DUMPDIR -type d -empty -delete >>$LOG 2>&1
