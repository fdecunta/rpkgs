#!/bin/sh

R_OPTIONS="--no-echo --no-save"

usage() {
	echo "usage: rpkgs [-dHrv] file1 ..."
	echo ""
	echo "Scan R files for packages used."
	echo ""
	echo "Options:"
	echo "  -H  print with filename"
	echo "  -d  dependencies"
	echo "  -r  recursive dependencies (implies -d)"
	echo "  -v  package version"
}

# The weird way of parsing args comes from base R scripts (INSTALL, check, etc.) 
# 'args' list should be passed as _one_ argument to R, where it is handled
# with 'commandArgs'. 

flags=

while getopts "dHhrv" arg
do
	case $arg in
	d) 	flags="${flags}d";;
	H) 	flags="${flags}H";;
	r) 	flags="${flags}rd";;  # r implies d
	v) 	flags="${flags}v";;
	h) 	usage; exit 0;;
	?) 	usage>&2; exit 1;;
	esac
done
shift $(($OPTIND - 1))

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

echo 'scanpkgs:::.scan_pkgs()' | R ${R_OPTIONS} --args "$flags" "$args"
