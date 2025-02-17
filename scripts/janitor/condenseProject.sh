#!/bin/bash

# set all global variables
thisDir=$(dirname $(realpath $0))
source $thisDir/../../../fsdb-minimal/scripts/core/getVar.sh

intro $0

debug=2

dbg $PROJECTSDIR

if [[ -z $1 ]]; then
    DIR=$PROJECTSDIR
else
    DIR="$1"
fi

for i in $(find "$DIR" -type d -name "*-fsdb" |grep -v "RECYC"); do 
    echo; 
    echo "$i"; 
    PID=$(basename "$i" |cut -d "_" -f 4); 
    outDir="$(echo "$i" |sed "s@${PID}.*@$PID@")"
    if [[ ! -d "$outDir" ]]; then
        echo "$outDir is not a valid directory for basename $i. Skipping."
    else
        echo "$i --> $outDir/"
        rsync -Sauv "$i" "${outDir}/"
    fi
done
