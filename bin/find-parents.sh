#!/bin/bash

usage()
{
   echo "$(basename $0) <pattern>"
   echo "  e.g. $(basename $0) libssl.so"
   exit 1
}

[ $# != 1 ] && usage

PATTERN=$1
find / -type f -perm /a+x -print0 |
    while read -d $'\0' FILE; do
        ldd "$FILE" | grep -q "$PATTERN" && echo "$FILE"
    done
