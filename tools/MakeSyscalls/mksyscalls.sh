#!/bin/sh
# Parse syscalls.h and idc files for each OS version, and produce syscalls_x.x.c

if [ $# -eq 0 ]; then
	echo "Usage: $0 <idcdir> <syscalls.h> <OS_version_number>*"
	echo "<OS_version_number> is (ncas|cas)-x.y[.z]"
	echo "The IDC files must be named OS_<version_number>.idc"
	echo "The output file names and the array variable names are derived from the name of <syscalls.h>"
	exit 1
fi

armdir="../../arm"
idcdir="$1"
shift
syscallfile="$1"
shift
syscallfilename=`basename "$syscallfile"`
syscallfilename_noext="${syscallfilename%%.h}"
syscallh_first_value_line=$((`grep -n START_OF_LIST "$syscallfile" | cut -d':' -f1` + 1))
syscallh_last_value_line=$((`grep -n  END_OF_LIST   "$syscallfile" | cut -d':' -f1` - 1))

for os_version in "$@"; do
	idcname="OS_${os_version}.idc"
	idcfile="$idcdir/$idcname"
	outfile="$armdir/${syscallfilename_noext}_${os_version}.c"
	echo "Generating `basename $outfile`..."
	echo "/* Each entry matches a symbol in syscalls.h. This file is generated by `basename $0`. */" > "$outfile"
	array_name=`echo "${syscallfilename_noext}_$os_version" | sed 's/[.-]/_/g'` # replace reserved characters with '_'
	echo "unsigned $array_name[] = {" >> "$outfile"
	syscallh_linenum=$((syscallh_first_value_line - 1))
	while [ $((syscallh_linenum + 1)) -le $syscallh_last_value_line ]; do
		syscallh_linenum=$((syscallh_linenum + 1))
		scallh_line=`head -$syscallh_linenum "$syscallfile" | tail -1`
		syscall_addr=0X0
		#contains_comment=`echo "$scallh_line" | egrep "^//"`;
		# If line not empty then
		if [ "x`echo $scallh_line | sed 's/\\r//g' | sed 's/\\n//g'`" != "x" ]; then
			syscall_name=`echo "$scallh_line" | sed 's/.\+\?e_\(\w\+\).*/\1/'`
			if [ -z "$syscall_name" ]; then
				continue
			fi
			idcline=`grep \"$syscall_name\" "$idcfile" | grep MakeName`
			if [ $? -ne 0 ]; then
				if ! $lastwarn; then
					echo ""
				fi
				echo -e "WARNING: symbol '$syscall_name' of '$syscallfilename' not found in '$idcname'"
				lastwarn=true
			else
				lastwarn=false
				syscall_addr=`echo "$idcline" | sed 's/.*\(0X[0-9A-F]\+\),.*/\1/g'`
			fi
			if [ $syscallh_linenum -eq $syscallh_first_value_line ]; then
				echo -en "\t  " >> "$outfile"
			else
				echo -en "\t, " >> "$outfile"
			fi
			if ! $lastwarn; then
				echo -n '.'
			fi
			echo "$syscall_addr" >> "$outfile"
		fi
	done
	echo "};" >> "$outfile"
	echo ""
done
