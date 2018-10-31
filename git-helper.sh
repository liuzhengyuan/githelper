#!/bin/bash

START_POINT=1
END_POINT=""
APPLY_ONLY=""

while getopts 's:e:a' OPT; do
    case $OPT in
        s)
                START_POINT="$OPTARG";;
        e)
                END_POINT="$OPTARG";;
        a)
                APPLY_ONLY="yes";;
        ?)
            echo "Usage: `$SHELL_NAME $0` [options] [path]"
    esac
done

shift $((OPTIND -1))
GIT_PATH=$1

echo start:$START_POINT end:$END_POINT apply:$APPLY_ONLY path:$GIT_PATH

if [ "$APPLY_ONLY" = "yes" ]; then
	if ! [ -d git-helper.success.patch ]; then
		mkdir git-helper.success.patch
	fi
	if ! [ -d git-helper.failure.patch ]; then
		mkdir git-helper.failure.patch
	fi

	for one_commit in `ls  *.patch`
	do
		if [ -f $one_commit ]; then
			git am $one_commit
			if [ $? -eq 0 ]; then
				printf "%s\n" "successed applying $one_commit"
				mv $one_commit git-helper.success.patch
			else
				echo failed applying $one_commit and exit
				git am --abort
				mv $one_commit git-helper.failure.patch
				exit
			fi	
		fi
	done
	exit
fi

if [ "$START_POINT"="1" ]; then
	START_POINT=`git log --pretty=oneline $GIT_PATH | sed -n "1p" | awk '{print $1}'`
fi

ALL_COMMITS=`git log --pretty=oneline $GIT_PATH | sed -n "/$START_POINT/,/$END_POINT/ p" | awk '{print $1}' | tac `

count=1
patch_name=""
for one_commit in $ALL_COMMITS
do
	echo format the ${count}th patch: $one_commit
	prefix_count=`printf "%04d" $count`
	patch_name=`git format-patch -n1 $one_commit`
	mv $patch_name $prefix_count--$patch_name
	count=$(($count+1))
done

