#!/bin/bash
<< README
This script generates hard links between the original data in the protected 
location ($STORAGEDIR/$IMPORTS/) and the accessible location ($LABDATADIR/$IMPORTS) 
and vice versa.

All variables are defined in the configuration file which is defined in getVar.sh

Parameters - none.

mode of function
- this script expects raw data (see $STACKEXTENSION) in the $USERs folder at 
$STORAGEDIR/$IMPORTS/.
- it generates a corresponding folder at e.g., $LABDATADIR/$IMPORTS 
and creates a hard link for the raw data set within that folder.
- subsequently it does the same in reverse: synchonizing the raw data in 
$LABDATADIR/$IMPORTS with $STORAGEDIR/$IMPORTS
- last but not least it makes sure, that the permission settings for the $IMPORTS 
folders are correct.

README
#fsdb-rev-date: 260123

usage() {
	printf "Usage: $(basename $0) [-f] [-h] [-d dir] [-p project]  
	
	-p	project/pattern
			This is a limiting string, which is included in the 'find' command.
			Setting this will limit the population of files to files, whose filenames 
			include this string.
				
	-d	directory
			This is the absolute path to the directory, which is supposed to be indexed.
				
	-f	force removal of all lock files
			Remove also the lock files of today. This is made for immediate 
			re-running a batch e.g., during testing or debugging.

	-h	help
			Displays this help.


" 1>&2;
	exit 1;
}

guardian() {
<<functionExplanation
The guardian is avoiding the assignment of options (e.g. -p) as arguments by
excluding everything, which starts with a hyphen from the pool of possible
arguments.
functionExplanation

	if [ "$(echo ${1:0:1})" == "-" ]; then
		warn "Guardian says: Invalid argument: $1" >&2
		usage
	fi
}

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

#debug=5

# set default values 
DEFAULTINDIR=$LABDATADIR/$IMPORTS/
INDIR=$DEFAULTINDIR
SEARCHSTRING="."
FORCEINDEX=0
PSTRING="" # $PSTRING prefixes '-p ' to the $SEARCHSTRING, so it can be used directly in downstream scripts
FSTRING="" # $FSTRING is '-f' when $FORCEINDEX is 1, so it can be used directly in downstream scripts
DSTRING="" # $DSTRING prefixes '-d ' to the provided directory, so it can be used directly in downstream scripts

# get options passed at call of this script
while getopts ":p:d:fh" opt; do
	case $opt in
		p)
			guardian $OPTARG
			dbg2 "Option -p was triggered, argument: $OPTARG" 
			SEARCHSTRING=$OPTARG
			PSTRING="-p $SEARCHSTRING"
			;;
		d)
			guardian $OPTARG
			dbg2 "Option -d was triggered, argument: $OPTARG"
			if [[ -d $OPTARG ]]; then
				INDIR=$(realpath $OPTARG)
				DSTRING="-d $INDIR"
			else
				error "$OPTARG is not a directory."
				usage
			fi
			;;
		f)
			guardian $OPTARG
			dbg2 "Option -f was triggered, this will force index generation"
			FORCEINDEX=1
			FSTRING="-f"
			;;
		h)
			usage
			;;
		\?)
			error "Invalid option: -$OPTARG" 
			exit 1
			;;
		:)
			error "Option -$OPTARG requires an argument." 
			exit 1
			;;
	esac
done
shift $((OPTIND-1))
dbg2 "parameters: $PSTRING $FSTRING $DSTRING"
dbg3 "search string: $SEARCHSTRING"

#============================
# FUNCTION DEFINITIONS
#============================

makeFsdbDir(){
# move files in $STORAGEDIR into their folder
		DIR=$1
		USERDIR=$DIR/$IMPORTS/${user}/
		if [[ ! -d $USERDIR ]]; then
			mkdir -p $USERDIR
		fi
		dbg2 "moving raw data of type ${stacktype} in $DIR/$IMPORTS/${user} into its fsdb-directory" |tee -a $LOG 
		for i in $(find $USERDIR -maxdepth 1 -mmin +10 -type f -name "*.$stacktype"); do
			fsdbCount=$(dirname $i |tr "/" "\n" |grep -ce -fsdb)
			if [[ $fsdbCount -eq 0 ]]; then
				echo "moving $i into fsdb-location. Skipping." >> $LOG
				out=$(echo "$i" |sed "s@\.$stacktype@$FSDB_EXT@");
			elif [[ $fsdbCount -eq 1 ]]; then
				echo "$i already in fsdb-location. Skipping." >> $LOG
				out=$(dirname $i)
			else
				echo "$i in false fsdb-location. Relocating" >> $LOG
				out=$(dirname $i |sed "s@${FSDB_EXT}.*@${FSDB_EXT}@")
			fi
			msg "$i --> $out"  |tee -a $LOG
			dbg3 "$i --> $out"
# create fsdb-folder
			mkdir -v $out >>$LOG 2>&1
# move image into new folder
			mv -fv $i $out >>$LOG 2>&1
		done
}

makeLinks(){
	INDIR=$1
	OUTDIR=$2
	dbg2 "linking data from $INDIR to $OUTDIR" |tee -a $LOG
	DIR=$INDIR
	for DIR in $(find $INDIR/$IMPORTS/${user}/ -type d -name "*$FSDB_EXT"); do
		for IMAGE in $(find $DIR -type f -name "*.$stacktype"); do
			out=$(echo $IMAGE |sed "s@$INDIR@$OUTDIR@");
			outDir=$(dirname $out);
			msg $IMAGE
			mkdir -vp $outDir >>$LOG 2>&1
			ln -v $IMAGE $out >>$LOG 2>&1
		done
	done
}

#============================
# FUNCTION CALLS
#============================

if [[ "$INDIR" != "$DEFAULTINDIR" ]]; then
	for stacktype in $STACKEXTENSION; do
		makeFsdbDir $INDIR
		makeLinks $INDIR
	done
else
	for user in $USER; do
		dbg "working for $user" |tee -a $LOG
		for stacktype in $STACKEXTENSION; do
	# make and populate fsdb-directories # DEPRECATED 
			makeFsdbDir $STORAGEDIR
			makeFsdbDir $LABDATADIR
	# synchonize the raw data in $STORAGEDIR and $LABDATADIR
			makeLinks $STORAGEDIR $LABDATADIR
			makeLinks $LABDATADIR $STORAGEDIR
		done
	done
fi
dbg2 "make sure all permissions are set correctly" |tee -a $LOG
dbg $(date)  |tee -a $LOG
bash $FIXPERMISSIONS $DSTRING $PSTRING $FSTRING
