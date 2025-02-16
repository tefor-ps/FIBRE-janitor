#!/bin/bash

if [[ -z $1 ]]; then
    DIR=/BUP/DATA/tps/labdata/projects/
else
    DIR="$1"
fi

for i in $(find "$DIR" -type d -name "*-fsdb"); do 
    echo; 
    echo $i; 
    PID=$(basename $i |cut -d "_" -f 4); 
    outDir=$(echo $i |sed "s@${PID}.*@$PID@")
    if [[ ! -d $outDir ]]; then
        echo "$outDir is not a valid directory for basename $i. Skipping."
    else
        echo "$i --> $outDir/"
        rsync -Sauv "$i" "${outDir}/"
    fi
done
