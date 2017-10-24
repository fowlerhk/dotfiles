#!/bin/sh
#
set -ue

TOPDIR=`pwd`
MNTDIR="$TOPDIR/mnt"

usage()
{
   echo "$0 <flat-vmdk-filename.vmdk>|<vmdk-mount-directory>"
   echo
   echo "e.g."
   echo "  $0 myedge-1-flat.vmdk   or"
   echo "  $0 myedge-1"
   echo
}


unmount_vmdk()
{
   echo "Unmounting the VMDK..."

   if mountpoint -q $MNTDIR/var/log; then
      umount -d $MNTDIR/var/log
   fi

   if mountpoint -q $MNTDIR/var/dumpfiles; then
      umount -d $MNTDIR/var/dumpfiles
   fi

   if mountpoint -q $MNTDIR/var/db; then
      umount -d $MNTDIR/var/db
   fi

   if mountpoint -q $MNTDIR; then
      umount -d $MNTDIR
   fi
}



# Make sure we are root
if [ `id -u` != 0 ]; then
   echo "Error: You must be root when running this script."
   exit 1
fi

if [ "$#" -ne 1 ] ; then
   echo "Error: Missing or incorrect arguments."
   usage
   exit 1
fi

VMDK_FILENAME=$1
VM_NAME=${VMDK_FILENAME%-flat.vmdk}
MNTDIR="$TOPDIR/$VM_NAME"

if ! mountpoint -q $MNTDIR; then
   echo "Error: Cannot find the mountpoint - $MNTDIR"
   usage
   exit 1
fi

unmount_vmdk
rm -rf $MNTDIR
