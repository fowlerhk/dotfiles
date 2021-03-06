#!/bin/sh
#
# This script creates vShieldEdge VM using the GOLD VM and the image file image-edge-edge.img.dist
# generated by ./doit.edge
#

set -ue

##
# Commands/Utilities used for OVF creation
##
TCROOT=/build/toolchain
MOUNT=$TCROOT/lin32/util-linux-ng-2.15/bin/mount
UMOUNT=$TCROOT/lin32/util-linux-ng-2.15/bin/umount
RM=$TCROOT/lin32/coreutils-6.12/bin/rm
CP=$TCROOT/lin32/coreutils-6.12/bin/cp
MKDIR=$TCROOT/lin32/coreutils-6.12/bin/mkdir
LN=$TCROOT/lin32/coreutils-6.12/bin/ln
LS=$TCROOT/lin32/coreutils-6.12/bin/ls
TAR=$TCROOT/lin32/tar-1.20/bin/tar
RENAME=$TCROOT/lin32/util-linux-2.13_pre7/usr/bin/rename
CAT=$TCROOT/lin32/coreutils-6.12/bin/cat
OVFTOOL_LD_LIBRARY_PATH=$TCROOT/lin64/libxml2-2.9.1/lib/
OVFTOOL=$TCROOT/lin64/ovftool-3.0.1-1/ovftool
SHA1SUM=$TCROOT/lin32/coreutils-6.12/bin/sha1sum
SED=$TCROOT/lin32/sed-4.1.5/bin/sed
CUT=$TCROOT/lin32/coreutils-6.12/bin/cut
PATCH=$TCROOT/lin32/patch-2.5.9/bin/patch
CHMOD=$TCROOT/lin32/coreutils-6.12/bin/chmod
CHOWN=$TCROOT/lin32/coreutils-6.12/bin/chown
GZIP=$TCROOT/lin32/gzip-1.3.5/bin/gzip
ZIP=$TCROOT/lin32/zip-3.0/bin/zip
STRIP=$TCROOT/lin32/binutils-2.17/x86_64-linux/bin/strip
FDISK=$TCROOT/lin64/util-linux-ng-2.15/sbin/fdisk
INSTALL=$TCROOT/lin32/coreutils-6.12/bin/install

TOPDIR=`pwd`
MNTDIR="$TOPDIR/mnt"
DO_CLEANUP=1

trap cleanup EXIT
cleanup()
{
   if [ $DO_CLEANUP -eq 1 ]; then
      echo "Cleaning up...."

      # Unmount the VMDK in case a build error occurred.
      unmount_vmdk

      $RM -rf $MNTDIR
   fi
}


##
# Helper function to get the partition offset to be used for loop mounting
##
get_partition_offset()
{
   vmdk=$1
   name=$2
   units=$($FDISK -l -u $vmdk 2>/dev/null | $SED -n 's/^Units.* = \([0-9]\+\) bytes.*/\1/p')
   start=$($FDISK -l -u $vmdk 2>/dev/null | $SED -n "/$name/s/.*$name *\*\? *\([0-9]\+\).*/\1/p")
   offset=$(($start * $units))
   echo $offset
}


##
# Create temporary directories and keep the required files in those dirs
##
create_directories()
{
   echo "Creating temporary directories....."

   [ -d $MNTDIR ] && $RM -rf $MNTDIR
   $MKDIR -p $MNTDIR
}

##
# This function
#  a. Untars the template VMDK files.
#  b. Mounts all partitions in the VMDK.
##
mount_554_vmdk()
{
   VMDK=$1
   echo "Mounting vmdk file.....$VMDK"

   if [ ! -e $VMDK ]; then
      echo "VMDK file '$VMDK' does not exist!"
      exit 1
   fi

   echo "VMDK Partition information:"
   $FDISK -l -u $VMDK 2>/dev/null

   # Mount root partition
   $MOUNT -oloop,offset=$(get_partition_offset $VMDK vmdk2) "$VMDK" $MNTDIR
   if [ $? -ne 0 ]; then
      echo "Failed to mount Root partition!"
      exit 1
   fi

   # Mount Log partition
   $MKDIR -p $MNTDIR/var/log
   $MOUNT -oloop,offset=$(get_partition_offset $VMDK vmdk3) "$VMDK" $MNTDIR/var/log
   if [ $? -ne 0 ]; then
      echo "Failed to mount Log partition!"
      exit 1
   fi

   DO_CLEANUP=0
}

unmount_554_vmdk()
{
   echo "Unmounting the VMDK..."

   if mountpoint -q $MNTDIR/var/log; then
      $UMOUNT -d $MNTDIR/var/log
   fi

   if mountpoint -q $MNTDIR; then
      $UMOUNT -d $MNTDIR
   fi
}

create_directories
mount_554_vmdk $1
