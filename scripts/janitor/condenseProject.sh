#!/bin/bash

# set all global variables
thisDir=$(dirname $(realpath $0))
source $thisDir/../../../fsdb-minimal/scripts/core/getVar.sh

intro $0   # display name of this script in cyan 

#debug=2   # debug level, overwrites the golbal debug level if not commented out.

# accept alternative path 
if [[ -z $1 ]]; then
    DIR=$PROJECTSDIR
else
    if [[ -d "$1" ]]; then
        DIR="$1"
    else
        error "$1 is not a valid directory. Exiting."
        exit 1
    fi
fi

# move all directories within $DIR, which are ending on $FSDB_EXT to their project-directory 
# the project-directory is named with the corresponding projectID (PID, e.g.; AJ-110-DR)
for i in $(find "$DIR" -type d -name "*${FSDB_EXT}" |grep -v "RECYC"); do 
    echo; 
    msg "$i"; 
    PID=$(basename "$i" |cut -d "_" -f 4)   # extract PID from file name
    outDir="$(echo "$i" |sed "s@${PID}.*@$PID@")"
    if [[ ! -d "$outDir" ]]; then
        echo "$outDir is not a valid directory for basename $i. Skipping."   #
    else
        msg "$i --> $outDir/"
        if [[ $debug -gt 1 ]]; then
            echo
            rsync -Sauv "$i" "${outDir}/"
        else
            rsync -Sau "$i" "${outDir}/"
        fi
    fi
done
