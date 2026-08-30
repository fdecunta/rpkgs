#!/bin/sh

set -e

prog="./rpkgs.sh"

test_dir="./testing_files"
outdir="${test_dir}/output"
expdir="${test_dir}/expected"

run_test () {
	title="$1"
	out="${outdir}/${title}.out"
	expected="${expdir}/${title}.expected"

	sh "$prog" ${test_dir}/${title}.R | sort > "$out"

	if [ ! -z "$(diff -q "$expected" "$out")" ]; then
		echo "Fail" "$title" 
	else 
		echo "Ok" "$title"
	fi
}

run_all () {
	run_test "library"
	run_test "require"
	run_test "doublecolon_1"
	run_test "p_load_test1"
	run_test "p_load_test2"
	run_test "p_load_test3"
}


echo "$(run_all)" | 
awk '
BEGIN { 
	count_ok = 0;
	count_fail = 0;
}
{
	printf("%s\t%s\n", $1, $2);
	$1 == "Ok" ? (count_ok++) : (count_fail++);
}
END {
	printf("\nSummary:\n");
	printf("Ok\t%d\n", count_ok); 
	printf("Fail\t%d\n", count_fail); 
}'
