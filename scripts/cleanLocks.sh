#!/bin/bash
<< README
This script is removing the lock files - which were generated during the 
secondary data generation (runner.sh). 

By default only lock files older than 1 day are removed.

Parameters: 
This script does not need any parameters however the following parameters can be 
provided:  
if $1 is 'today', ALL lock files will removed; including the ones of today.


README
#fsdb-rev-date: 251106

# get location of this script
thisDir=$(dirname $(realpath "$0"))

# find and source getVar.sh to set all global variables
source getVar
intro $(basename $0)

#debug=2

if [[ "$1" == "today" ]]; then
# remove all lock files 
	find $LABDATADIR/imports/ -type f -name "*$SEARCHSTRING*.lock" -delete 
else
# remove all lock files older than 24h
	find $LABDATADIR/imports/ -type f -mtime +1 -name "*.lock" -delete 
fi
