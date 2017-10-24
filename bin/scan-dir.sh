#!/bin/bash

# Make sure we are root
if [ `id -u` != 0 ]; then
        echo "ERROR: You must be root when running this script"
        exit -1
fi

if [ $# != 1 ] ; then
        echo "Usage: $0 <directory>"
        exit -1
fi

TMPFILE=mkstmp
find $1 -type f -printf "%p;file;%m;%U;%G;1334909061;%s\n" > $TMPFILE
#find $IMAGE_DIR -type c -printf "%p;char;%m;%U;%G;<major>;<minor>\n" >> $TMPFILE
#find $IMAGE_DIR -type b -printf "%p;block;%m;%U;%G;<major>;<minor>\n" >> $TMPFILE
find $1 -type p -printf "%p;pipe;%m;%U;%G\n" >> $TMPFILE
find $1 -type d -printf "%p;directory;%m;%U;%G;1334909061;%s\n" >> $TMPFILE
find $1 -type l -printf "%p;link;%l;good\n" >> $TMPFILE
# Make sure file and dir modes have 4 digit mode.
# The above finds will only output modes like 755 instead of 0755.
for name in file directory; do
   sed -i "s/;${name};\([0-9][0-9][0-9]\);/;${name};0\1;/" $TMPFILE
done
#Strip off the full path
sed -i "s@^$IMAGE_DIR;.*\$@@" $TMPFILE
sed -i "s@^$IMAGE_DIR/\(.*\)@\1@" $TMPFILE
sed -i "s@;$IMAGE_DIR/\(.*\)@;\1@" $TMPFILE
sed -i '/^$/d' $TMPFILE
cp -f $TMPFILE directory-fsscan.log
sort -o directory-fsscan.log directory-fsscan.log
rm $TMPFILE
cat directory-fsscan.log

