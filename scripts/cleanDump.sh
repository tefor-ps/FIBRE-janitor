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

# get variables of fsdb from getVar.sh
if ! source getVar; then
	dir=$thisDir 
	for _ in $(seq 1 4); do
		GV=$(find "$dir" -name "getVar.sh" -print -quit)
		if [[ -f $GV ]]; then 
			source "${GV}"
			break 
		else
			dir="$(dirname "$dir")"
		fi
	done
	if [[ ! -f "${GV}" ]]; then
		echo "ERROR: Can't find getVar.sh"
		exit 555
	fi
fi
intro $(basename $0)

#debug=2

## clean dump; 
# remove everything older than 0.5 year from dump. 
find $DUMPDIR -mtime +180 -delete >>$LOG 2>&1
# remove left-over (empty) folders
find $DUMPDIR -type d -empty -delete >>$LOG 2>&1
