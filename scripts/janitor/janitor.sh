#!/bin/bash
<<README
This script is a simple wrapper for other scripts, which are cleaning up the fsdb.

This cleaning mechanism is subdivided into multiple scripts to give the systems
administrator the opportunity of running them also separately through individual
cron-jobs or manually.

Parameters: 
This script does not need any parameters however the following options can be 
provided:  
   
	-p	project/pattern
			This is a limiting string, which is included in the 'find' command.
			Setting this will limit the population of files to files, whose filenames 
			include this string.
				
	-f	force removal of all lock files
			Remove also the lock files of today. This is made for immediate 
			re-running a batch e.g., during testing or debugging.

	-h	help
			Displays help.

Procedure:
- index $LABDATADIR and $STORAGEDIR
- clean the $IMPORTS directories of $LABDATADIR and $STORAGEDIR
- create project directories at $PROJECTSDIR
- clean the $EXCHANGEDIR
- clean temporary data ($LOGDIR, $INDEXDIR, debugger, /tmp/
- clean $DUMPDIR
- remove unwanted microscope-specific artifacts
- remove processing artifacts of the fsdb
README
#fsdb-rev-date: 251015

#TODO: makeProjectLinks is not creating subdirectories

fsdbDir=../../../fsdb-minimal
debug=2

usage() {
	printf "Usage: $(basename $0) [-f] [-h] [-p project]  
	
	-p	project/pattern
			This is a limiting string, which is included in the 'find' command.
			Setting this will limit the population of files to files, whose filenames 
			include this string.
				
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

# find and source getVar.sh to set all global variables
thisDir=$(dirname $(realpath "$0"))
if [[ -z $1 ]]; then
	if [[ "$thisDir" =~ /fsdb[0-9]{2}/ ]]; then
		FSDBDIR="$(realpath $thisDir |sed -r 's@(/fsdb[0-9]{2}/).*@\1@')"
	else
		FSDBDIR="$(realpath $thisDir/../..)"
	fi
	gv=$(find "$FSDBDIR" -type f -name getVar.sh)
	#source $thisDir/../scripts/core/getVar.sh
else 
	gv=$(find "$1" -type f -name getVar.sh)
	#source $1/core/getVar.sh
fi

if [[ -f "$gv" ]]; then
	source "$gv"
else
	echo "ERROR: Can't find getVar.sh"
	exit 555
fi

intro $(basename $0)

#debug=2

FORCEINDEX=0
PSTRING="" # $PSTRING prefixes '-p ' to the $SEARCHSTRING, so it can be used in directly downstream scripts
FSTRING="" # $FSTRING is '-f' when $FORCEINDEX is 1, so it can be used in directly downstream scripts

# get options passed at call of this script
#TODO: implement save-option? 
while getopts ":p:fh" opt; do
	case $opt in
		p)
			guardian $OPTARG
			dbg2 "Option -p was triggered, argument: $OPTARG" 
			SEARCHSTRING=$OPTARG
			PSTRING="-p $SEARCHSTRING"
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
dbg2 "parameters: $PSTRING $FSTRING"
dbg3 "search string: $SEARCHSTRING"

# update index - this call gives the user the power to force the creation of a new index before anything else 
dbg "forcing new index generation"
# $MAKEINDEX is defined in core.config
dbg2 "$MAKEINDEX $PSTRING $FSTRING"
if [[ $debug -gt 0 ]]; then
	bash $MAKEINDEX $PSTRING $FSTRING 2>&1 |tee -a $LOG
else
	bash $MAKEINDEX $PSTRING $FSTRING 2>&1 >> $LOG
fi

# put the raw data and their secondary data into the right locations
dbg "move data into the right locations"

# synchronize the data in the hidden storage location (STORAGESDIR) with the accessible one (LABDATADIR)
dbg "make sure, that the images are at the right location in $STORAGEDIR and $LABDATADIR"
dbg2 $CLEANIMPORTS
if [[ $debug -gt 0 ]]; then
	bash $CLEANIMPORTS 2>&1 |tee -a $LOG
else
	bash $CLEANIMPORTS 2>&1 >> $LOG
fi
# this is also calling $FIXPERMISSIONS which is setting the permissions.

# re-sort data in LABDATADIR/IMPORTS into project based directories in PROJECTSDIR
dbg "generate project directories"
dbg2 "$MAKEPROJECTDIRS $PSTRING $FSTRING"
if [[ $debug -gt 0 ]]; then
	bash $MAKEPROJECTDIRS $PSTRING $FSTRING 2>&1 |tee -a $LOG
else
	bash $MAKEPROJECTDIRS $PSTRING $FSTRING 2>&1 >> $LOG
fi

# remove all data older than 30 days from the directory EXCHANGEDIR
dbg "clean exchange folder"
dbg2 $CLEANEXCHANGE
if [[ $debug -gt 0 ]]; then
	bash $CLEANEXCHANGE 2>&1 |tee -a $LOG
else
	bash $CLEANEXCHANGE 2>&1 >> $LOG
fi

# remove all data older than 30 days from the directory /tmp/
dbg "clean the /tmp directory from outdated files"
dbg2 $CLEANTMP
if [[ $debug -gt 0 ]]; then
	bash $CLEANTMP 2>&1 |tee -a $LOG
else
	bash $CLEANTMP 2>&1 >> $LOG
fi

# remove all data older than 180 days from the directory DUMPDIR
dbg "remove data older than 180 days from dump"
dbg2 $CLEANDUMP
if [[ $debug -gt 0 ]]; then
	bash $CLEANDUMP 2>&1 |tee -a $LOG
else
	bash $CLEANDUMP 2>&1 >> $LOG
fi

# generate a new index. Here we always force the index generation, because 
# 1) an index for sure already exists 
# 2) newly generated data need to be indexed.
dbg "generate new index"
if [[ $debug -gt 0 ]]; then
	bash $MAKEINDEX -f $PSTRING 2>&1 |tee -a $LOG
else
	bash $MAKEINDEX -f $PSTRING 2>&1 >> $LOG
fi

# remove 'lifext'-files 
dbg "remove unwanted lifext files"
dbg2 $CLEANLIFEXT
if [[ $debug -gt 0 ]]; then
	bash $CLEANLIFEXT 2>&1 |tee -a $LOG
else
	bash $CLEANLIFEXT 2>&1 >> $LOG
fi

# remove old lock files
dbg "remove the lock files of yesterday"
dbg2 "$CLEANLOCKS $FSTRING $PSTRING"
if [[ $debug -gt 0 ]]; then
	bash $CLEANLOCKS $FSTRING $PSTRING 2>&1 |tee -a $LOG
else
	bash $CLEANLOCKS $FSTRING $PSTRING 2>&1 >> $LOG
fi


