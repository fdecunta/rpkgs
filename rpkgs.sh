#!/bin/sh

R_OPTIONS="--no-echo --no-save"

usage() {
	echo "usage: rpkgs [-dHrv] file1 ..."
	echo ""
	echo "Scan R files for packages used."
	echo ""
	echo "Options:"
	echo "  -H  print filename for each package"
	echo "  -d  show dependencies"
	echo "  -r  show recursive dependencies (implies -d)"
	echo "  -v  show package version"
}

Hflag=
dflag=
rflag=
vflag=

while getopts "dHhr" arg
do
	case $arg in
	d) 	dflag=1;;
	H) 	Hflag=1;;
	r) 	rflag=1; dflag=1;;   # r implies d
	v) 	vflag=1;;
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

if test -z "${args}"; then
	echo "error: no files">&2
	usage>&2
	exit 1
fi

echo 'scanpkgs::scan_pkgs()' | R ${R_OPTIONS} --args "$args"
