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


