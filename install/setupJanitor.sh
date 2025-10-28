#!/bin/bash
<<README

README

#fsdb-rev-date: 251028; tested, OK

## ======
## FUNCTION DEFINITIONS
## ======

function fail(){
	#intro "$@"
	date
	printf "\033[31mError in $(basename $0):${FUNCNAME[2]}:${FUNCNAME[1]} $@ \033[0m"
	printf "\033[31m\nExiting.\033[0m\n"
	exit 128
}

function sudoer() {
## ROOT PRIVILEDGES
# Because for the installation of software and generation of directories 
# on shares with limited write permissions root rights are needed, check for 
# these at the very beginning. 
	if [ "$(whoami)" != "root" ]; then 
		printf $'\r\e[2K\t\e[31;1;40m'"WARNING: This script needs to be run with root-priviledges."$'\e[0m\n' 
		exit
	fi
}

function error() { 
	if [[ -t 2 ]] ; then 
		date >> $LOG; 
		printf $'\e[37;1;41m'"\r\e[2KERROR:\t$0: $@"$'\e[0m\n' |tee -a $LOG
	else 
		echo "$@"
	fi >&2
}

## ======
## FUNCTION CALLS
## ======

# make sure, that the sourcing script is run as superuser/root
sudoer

# define FSDBDIR, which is the root of the fsdb, 
# dynamically on the basis of the location of this script
thisDir=$(dirname $(realpath $0))
if [[ -z $1 ]]; then
	if [[ "$thisDir" =~ /fsdb[0-9]{2}/ ]]; then
		FSDBDIR="$(realpath $thisDir |sed -r 's@(/fsdb[0-9]{2}/).*@\1@')"
	else
		FSDBDIR="$(realpath $thisDir/../..)"
	fi
	gv=$(find "$FSDBDIR" -type f -name getVar.sh)
else 
	gv=$(find "$1" -type f -name getVar.sh)
fi

# set all global variables
if [[ -f "$gv" ]]; then
	source "$gv"
else
	ADMINDIR="/tmp/"
	LOG="$ADMINDIR/$(basename $0 .sh).log"
	REPO=https://gitlab.com/tefor/fsdb-janitor.git
	error "Can't locate getVar.sh."
fi

# https://stackoverflow.com/a/226724
while true; do 
    intro "Do you wish to get configs from ${repo}? [Y/n]: "
    read -p $'\t' -i "Y" -e ans
    case $ans in
        [Yy]* ) getrepo=1; break;;
        [Nn]* ) getrepo=0; break;;
        * ) intro "Please answer yes or no.";;
    esac
done

# check user input
if [[ ! -d $FSDBDIR ]]; then
	fail "Provide the path to the fsdb-instance you want to import the configs to."
else
# create temporary directory for download and unpacking.
	TMPDIR=$(mktemp -d)
	cd "$TMPDIR" || fail "Can't access $TMPDIR"
# clone repo into temporary directory	
	intro "Importing configs from $REPO to $TMPDIR"
	git clone $REPO || fail
# rsync (updating) repo into final location 
	repoDir="$(basename $REPO .git)"
	mkdir -pv "${repoDir}"
	sudo rsync -Sauv "${TMPDIR}/${repoDir}/" "${FSDBDIR}/${repoDir}/" || fail 
fi