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
IMAGE_DIR=$1

# Find out what was added by the build.
TMPFILE=$(mktemp /tmp/fsscan-XXXXX)
HARDLINK_FILE=$(mktemp /tmp/fsscan-hardlink.XXXXX)

# Locate all files and hardlinks and store in a temp file sorted by inode, with a blank line
# between each set of filenames referencing one inode.
find $IMAGE_DIR -type f -links +1 -printf '%20i %p,%m,%U,%G,%s\n' | sort -n | uniq -w 21 --all-repeated=separate > $HARDLINK_FILE
sed -i 's/^[ \t]*[0-9]* //' $HARDLINK_FILE

# Walk through the temp file and generate the fsscan entries for each group of filenames.
# Create one as a 'file' entry and all others 'hardlinks'.
filename=
link=
while read -r line || [[ -n "$line" ]]; do
   if [ -n "$line" ]; then
      IFS=$'\t' read -r filename mode uid gid size \
          < <(sed 's/\(.*\),\([0-9]*\),\([0-9]*\),\([0-9]*\),\([0-9]*\)/\1\t\2\t\3\t\4\t\5/' \
                   <<< "$line"
             )
      [ -z $link ] && link=$filename
      if [ "$filename" == "$link" ]; then
         echo "$filename;file;$mode;$uid;$gid;1334909061;$size" >> $TMPFILE
      else
      echo "$filename;hardlink;$link" >> $TMPFILE
      fi
   else
      filename=
      link=
   fi
done < $HARDLINK_FILE
#rm $HARDLINK_FILE

# Ok, hardlinks are done. Now lets find all the files, directories, symlinks and pipes.
find $IMAGE_DIR -type f -links 1 -not -path "$IMAGE_DIR/tmp/*" -printf "%p;file;%m;%U;%G;1334909061;%s\n" >> $TMPFILE
find $IMAGE_DIR -type p -not -path "$IMAGE_DIR/tmp/*" -printf "%p;pipe;%m;%U;%G\n" >> $TMPFILE
find $IMAGE_DIR -type d -not -path "$IMAGE_DIR/tmp/*" -printf "%p;directory;%m;%U;%G;1334909061;%s\n" >> $TMPFILE
find $IMAGE_DIR -type l -not -path "$IMAGE_DIR/tmp/*" -printf "%p;link;%l;good\n" >> $TMPFILE

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
# Sort the fsscan log by filename only. Output to stdout.
sort -k1,1 -t';' $TMPFILE
rm -f $TMPFILE
