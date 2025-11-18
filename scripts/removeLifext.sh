#!/bin/bash
<<README
This script removes the Leica lifext-files, which are generated automatically by the LASX software.

README
#fsdb-rev-date: 251105

# get location of this script
thisDir=$(dirname $(realpath "$0"))

# find and source getVar.sh to set all global variables
source getVar
intro $(basename $0)

#debug=2

for dir in $STORAGEDIR $LABDATADIR; do 
	for i in $(find $dir -type f -name "*.lifext"); do
		rm -f $i
	done
done