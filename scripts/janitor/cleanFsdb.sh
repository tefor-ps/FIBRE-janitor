#!/bin/bash

# set all global variables
thisDir=$(dirname $(realpath $0))
source $thisDir/../core/getVar.sh

intro $0

debug=2

FSDB_EXTDEF="-fsdb"
FSDB_EXT="${FSDB_EXT:-${FSDB_EXTDEF}}"
SECDATA_EXTDEF="-secData"
SECDATA_EXT="${SECDATA_EXT:-${SECDATA_EXTDEF}}"

var ar=""

el_index() {
    cnt=0; for el in "${ar[@]}"; do
        [[ $el == "$1" ]] && echo $cnt && break
        ((++cnt))
    done
}

mvImg(){
# create fsdb-folder
			mkdir -pv $2 >>$LOG 2>&1
# move image into new folder
			#rsync -Sauv --remove-source-files $i $out >>$LOG 2>&1
			ln -v $1 $2 >>$LOG 2>&1
			if [[ "$(dirname $1)" != $2 ]]; then
				rm -v $1
			fi
}

makeFsdbDir(){
# move files in $STORAGEDIR into their folder
		FILE="$1"
#		dbg "moving $(realpath $FILE) into its fsdb-directory" |tee -a $LOG 
		for i in $(find "$(dirname $(realpath $FILE))" -type f -name "$(basename $FILE)"); do
			fsdbCount=$(dirname $i |tr "/" "\n" |grep -ce "$FSDB_EXT")
			sdCount=$(dirname $i |tr "/" "\n" |grep -ce "$SECDATA_EXT")
            dbg3 "$FSDB_EXT $fsdbCount"
			if [[ $fsdbCount -eq 0 && $sdCount -eq 0 ]]; then
				dbg "$i in wrong location. Moving $i into fsdb-location." |tee $LOG
				out=$(echo "$i" |sed "s@\.$stacktype@$FSDB_EXT@");
                msg "$i --> $out"  |tee -a $LOG
                dbg2 "$i --> $out"
				mvImg $i $out
			elif [[ $fsdbCount -eq 1 && $sdCount -eq 0 ]]; then
				dbg "$i already in fsdb-location. Skipping." |tee $LOG
			#	out=$(dirname $i)
			elif [[ $fsdbCount -eq 0 && $sdCount -eq 1 ]]; then
				dbg "$i in secData location. Moving $i into fsdb-location." |tee $LOG
				sdd=$(echo $i |sed "s@${SECDATA_EXT}.*@${SECDATA_EXT}@")
				out=$(echo $sdd |sed "s@${SECDATA_EXT}@${FSDB_EXT}@")
				mvImg $i $out
				#rsync -Sauv --remove-source-files $sdd $out/ >>$LOG 2>&1
				mv -v $sdd ${out}/
			elif [[ $fsdbCount -eq 1 && $sdCount -eq 1 ]]; then
				dbg "$i in strange location. Moving $i into fsdb-location." |tee $LOG
				ar=($(echo $i |sed 's@/@ @g'))
				sddind=$(el_index $SECDATA_EXT)
				fsdbind=$(el_index $FSDB_EXT)
				sdd=$(echo $i |sed "s@${SECDATA_EXT}.*@${SECDATA_EXT}@")
				out=$(echo $i |sed "s@${FSDB_EXT}.*@${FSDB_EXT}@")
				mvImg $i $out
				if [[ $sddind -gt $fsdbind ]]; then
					mv -v $sdd ${out}/
				else
					mv -v $out $sdd/..
					newOut=$(echo $sdd |sed "s@${SECDATA_EXT}@${FSDB_EXT}@")
					mv -v $sdd $newOut
				fi
			else
				dbg  "$i in false fsdb-location. Relocating." |tee $LOG
				out=$(dirname $i |sed "s@${FSDB_EXT}.*@${FSDB_EXT}@")
                msg "$i --> $out"  |tee -a $LOG
                dbg2 "$i --> $out"
				mvImg $i $out
			fi
		done
}

if [[ -z $1 ]]; then
    DIR=$(pwd)
else
    DIR="$1"
fi

for stacktype in $STACKEXTENSION; do
    for FILE in $(find "$DIR" -type f -name "*${stacktype}"); do 
        makeFsdbDir $FILE
    done
done

find "$DIR" -type d -empty -delete

dbg "done."