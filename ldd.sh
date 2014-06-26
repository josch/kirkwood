#!/bin/sh -xe

ld_lib_path="/usr/lib /lib /usr/lib32 /lib32 /usr/lib64 /lib64"

lib_put () { eval lib_"$1"="$2"; }
lib_get () { eval echo \$lib_"$1"; }


dump()
{
	objdump -p "$1" 2>/dev/null | while read line; do
		case $line in
		*file\ format*)
			;;
		Dynamic\ Section:)
			;;
		*NEEDED*)
			lib=${line#*NEEDED}
			lib_put $lib none
			echo $lib
			;;
		esac
	done
}

load_ldsoconf()
{
	while read line; do
		line=${line%%#*}

		if [ "$line" = "" ]; then
			continue
		fi

		case $line in include*)
			line=${line#include}
			for incl in $line; do
				load_ldsoconf $incl
			done
			continue
			;;
		esac

		ld_lib_path=$ld_lib_path" $line"
	done < "$1"
}

if [ "$#" -eq 0 ]; then
	echo $0: missing argument
	exit 1
fi

OBJDUMP=`which objdump`
if [ "$?" -ne 0 ]; then
	echo $0: objdump: command not found - install binutils packages
	exit 1
fi

load_ldsoconf /etc/ld.so.conf

ld_lib_path=$LD_LIBRARY_PATH" $ld_lib_path"
for path in $ld_lib_path; do
	if [ -d $path ]; then
		ld_tmp=$ld_tmp" $path"
	fi
done
ld_lib_path=$ld_tmp

for file in "$@"; do
	if [ "$#" -gt 1 ]; then
		echo "$file:"
	fi

	if [ ! -f "$file" ]; then
		echo "ldd: $file: No such file or directory" >&2
		continue
	fi

	for lib in `dump "$file"`; do
		echo lib_get $lib
	done
done


