#!/bin/bash
<<README
This script is deleting data, which is older than 180 days, from the $DUMPDIR  

This script is part of the janitor-job

mode of function:
- find in $DUMPDIR all files older than 180 days and remove them.
- find in $DUMPDIR all empty folders (relicts of cleanup) and remove them.
README
#fsdb-rev-date: 251015

# find and source getVar.sh to set all global variables
thisDir=$(dirname $(realpath "$0"))
if [[ -z $1 || "$1" =~ "-" ]]; then
	if [[ "$thisDir" =~ /fsdb[0-9]{2}/ ]]; then
		FSDBDIR="$(realpath $thisDir |sed -r 's@(/fsdb[0-9]{2}/).*@\1@')"
	else
		FSDBDIR="$(realpath $thisDir/../..)"
	fi
	gv=$(find "$FSDBDIR" -type f -name getVar.sh)
else
	if [[ -d $1 ]]; then
		gv=$(find "$1" -type f -name getVar.sh)
	else
		gv=$(find $(dirname "$1") -type f -name getVar.sh)
	fi
fi

if [[ -f "$gv" ]]; then
	source "$gv"
else
	echo "ERROR: Can't find getVar.sh"
	exit 555
fi

intro $(basename $0)

#debug=2

## clean dump; 
# remove everything older than 0.5 year from dump. 
find $DUMPDIR -mtime +180 -delete >>$LOG 2>&1
# remove left-over (empty) folders
find $DUMPDIR -type d -empty -delete >>$LOG 2>&1
