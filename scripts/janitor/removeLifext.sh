#!/bin/bash
<<README
This script removes the Leica lifext-files, which are generated automatically by the LASX software.

README
#fsdb-rev-date: 251105


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
	gv=$(find "$1" -type f -name getVar.sh)
fi

if [[ -f "$gv" ]]; then
	source "$gv"
else
	echo "ERROR: Can't find getVar.sh"
	exit 555
fi

intro $(basename $0)

#debug=0

for dir in $STORAGEDIR $LABDATADIR; do 
	for i in $(find $dir -type f -name "*.lifext"); do
		rm -f $i
	done
done