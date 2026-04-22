#!/bin/bash
<<README
This script removes the Leica lifext-files, which are generated automatically by the LASX software.

README
#fsdb-rev-date: 251105

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

for dir in $STORAGEDIR $LABDATADIR; do 
	for i in $(find $dir -type f -name "*.lifext"); do
		rm -f $i
	done
done