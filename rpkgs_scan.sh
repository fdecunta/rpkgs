#!/bin/sh

# Scan R pkgs from files.
#
# usage:

usage() {
	echo "usage: rpkgs [-dHr] file ..."
	echo ""
	echo "Scan R files for packages used."
	echo ""
	echo "Options:"
	echo "  -H  print filename for each package"
	echo "  -d  show dependencies"
	echo "  -r  show recursive dependencies (implies -d)"
}


Hflag=
dflag=
rflag=

while getopts "dHhr" arg
do
	case $arg in
	d) 	dflag=1;;
	H) 	Hflag=1;;
	r) 	rflag=1; dflag=1;; # r implies d
	h) 	usage; exit 0;;
	?) 	usage>&2; exit 1;;
	esac
done
shift $(($OPTIND - 1))

# The way of parsing args comes from base R scripts (INSTALL, check, etc.) 
# 'args' list should be passed as _one_ argument to R, where it is handled
# with 'commandArgs'. 

args=
while test -n "${1}"; do
	if test -f "${1}"; then
		args="${args}nextArg${1}"
	else
		echo "Error: "${1}" not a file">&2
	fi
	shift
done

Rscript scanner.R --args "$args"
# R --no-restore --no-echo --args "$args"


