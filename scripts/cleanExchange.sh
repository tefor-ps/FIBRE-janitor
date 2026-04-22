#!/bin/bash
<<README
This script is cleaning the $EXCHANGEDIR 
It moves everything older than $maxAge days from $EXCHANGEDIR into the $DUMPDIR

This script is part of the janitor-job

mode of function:
- find all files in $EXCHANGEDIR, which are older than $maxAge days
- generate corresponding directory in $DUMPDIR
- move these files to $DUMPDIR
- delete remaining empty folders from $EXCHANGEDIR

README
#fsdb-rev-date: 251112

maxAge=60

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

tmpList=/tmp/cleanExchange.txt

## clean exchange
# make list of files to dump (trashlist)
find $EXCHANGEDIR/ -mtime +${maxAge} |grep -v $INDEXDIR > $tmpList
# move items on trashlist to dump
while read i; do
	dump=$(dirname $i |sed "s@$EXCHANGEDIR@$DUMPDIR@")
	dbg "$dump"
	mkdir -p "$dump"
	mv -f "$i" "$dump"
done < $tmpList  >>$LOG 2>&1
# remove remaining empty directories from $EXCHANGEDIR
find $EXCHANGEDIR -type d -empty -delete >>$LOG 2>&1
# remove trashlist
rm $tmpList


