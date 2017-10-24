#!/bin/bash
#
# Helper script to mount NSX Edge partitions from VMDK flat files.
# Procedure:
#   1) Obtain the flat VMDK files for the NSX Edge. At minimum, there are two
#      *-flat.vmdk files for every NSX Edge VM. Compact & large have two, quadlarge
#      and xlarge have 3. Get them all.
#   2) Copy the vmdk files to a Linux machine running (preferrably) a recent version
#      of Ubuntu. However, this script may work just fine on other distros.
#   3) Invoke the 'mount-vmdk.sh' script and specify the size (optional) and the FIRST
#      vmdk of the NSX Edge VM. See usage info below.
#   4) Assuming successful mounting, a directory called 'mnt' has been created at the current
#      working directory, inside which you will find the NSX Edge partitions mounted.
#   5) When finished, invoke 'unmount-vmdk.sh, with no arguments, to unmount everything.

TOPDIR=`pwd`
DO_CLEANUP=1

trap cleanup EXIT
cleanup()
{
   if [ $DO_CLEANUP -eq 1 ]; then
      echo "Cleaning up...."

      # Unmount the VMDK in case a build error occurred.
      unmount_vmdk

      rm -rf $MNTDIR
   fi
}


##
# Helper function to get the partition offset to be used for loop mounting
##
get_partition_offset()
{
   vmdk=$1
   name=$2
   units=$(fdisk -l -u $vmdk 2>/dev/null | sed -n 's/^Units.* = \([0-9]\+\) bytes.*/\1/p')
   start=$(fdisk -l -u $vmdk 2>/dev/null | sed -n "/$name/s/.*$name *\*\? *\([0-9]\+\).*/\1/p")
   offset=$(($start * $units))
   echo $offset
}


##
# Create temporary directories and keep the required files in those dirs
##
create_directories()
{
   [ -d $MNTDIR ] && rm -rf $MNTDIR
   mkdir -p $MNTDIR
}

##
# This function
#  a. Untars the template VMDK files.
#  b. Mounts all partitions in the VMDK.
##
mount_vmdk()
{
   VMDK_ROOT="${VM_NAME}-flat.vmdk"
   VMDK_VAR="${VM_NAME}_2-flat.vmdk"
   if [ ! -e "$VMDK_ROOT" ]; then
      echo "Error: Failed to locate root vmdk file - $VMDK_ROOT"
      usage
      exit 1
   fi
   # Make sure the additional var disk is present for quadlarge and xlarge.
   # /var/db and /var/log are located on this extra disk for thoses Edge sizes.
   case "$SIZE" in
      quadlarge|xlarge)
         if [ ! -e "$VMDK_VAR" ]; then
            echo "Error: Missing required vmdk file for $SIZE edge."
            echo "Error: Failed to locate var vmdk file - $VMDK_VAR"
            exit 1
         fi
         ;;
   esac

   echo "Mounting vmdk file.....$VMDK_ROOT"
   echo "Root VMDK Partition information:"
   fdisk -l -u $VMDK_ROOT 2>/dev/null
   case "$SIZE" in
      quadlarge|xlarge)
         fdisk -l -u $VMDK_VAR 2>/dev/null
         ;;
   esac

   # Mount root partition (always on first VMDK)
   mount -oloop,offset=$(get_partition_offset $VMDK_ROOT vmdk1) "$VMDK_ROOT" $MNTDIR
   if [ $? -ne 0 ]; then
      echo "Failed to mount Root partition!"
      exit 1
   fi

   # Mount AppData partition
   mkdir -p $MNTDIR/var/db
   case "$SIZE" in
      quadlarge|xlarge)
         # /var/db is on 1st partition of var disk.
         mount -oloop,offset=$(get_partition_offset $VMDK_VAR vmdk1) "$VMDK_VAR" $MNTDIR/var/db
         ;;
      *)
         # /var/db is on 2nd partition of root vmdk.
         mount -oloop,offset=$(get_partition_offset $VMDK_ROOT vmdk2) "$VMDK_ROOT" $MNTDIR/var/db
         ;;
   esac
   if [ $? -ne 0 ]; then
      echo "Failed to mount AppData partition!"
      exit 1
   fi

   # Mount Dumpfiles partition
   mkdir -p $MNTDIR/var/dumpfiles
   mount -oloop,offset=$(get_partition_offset $VMDK_ROOT vmdk3) "$VMDK_ROOT" $MNTDIR/var/dumpfiles
   if [ $? -ne 0 ]; then
      echo "Failed to mount Dumpfiles partition!"
      exit 1
   fi

   # Mount Log partition
   mkdir -p $MNTDIR/var/log
   case "$SIZE" in
      quadlarge|xlarge)
         # /var/log is on 2nd partition of var disk.
         mount -oloop,offset=$(get_partition_offset $VMDK_VAR vmdk2) "$VMDK_VAR" $MNTDIR/var/log
         ;;
      *)
         # /var/db is on 4th partition of root vmdk.
         mount -oloop,offset=$(get_partition_offset $VMDK_ROOT vmdk4) "$VMDK_ROOT" $MNTDIR/var/log
         ;;
   esac
   if [ $? -ne 0 ]; then
      echo "Failed to mount Log partition!"
      exit 1
   fi

   DO_CLEANUP=0
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

usage()
{
   echo "$0 [-s|--size compact|large|quadlarge|xlarge] <flat-vmdk-filename.vmdk>"
   echo "  Default size is compact, if not specified."
   echo
   echo "  IMPORTANT NOTE: If you are mounting vmdks from a quadlarge or xlarge,"
   echo "  then you SHOULD provide the size argument. Failure to do so will result in"
   echo "  empty /var/log and /var/db disks being mounted."
   echo
   echo "e.g."
   echo "  $0 -s compact myedge-1-flat.vmdk"
   echo
}


# Make sure we are root
if [ `id -u` != 0 ]; then
   echo "Error: You must be root when running this script."
   exit 1
fi

# Process cmdline arguments
SIZE=compact # default to compact edge
while :
do
   case "$1" in
   -s|--size)
      case "$2" in
      compact|large|xlarge)
         SIZE="$2"
         ;;
      qlarge|quadlarge)
         SIZE=quadlarge
         ;;
      *)
         echo "Error: Unknown size: $2" >&2
         usage
         exit 1
         ;;
      esac
      shift 2
      ;;
   -*) # Unknown option
      echo "Error: Unknown option: $1" >&2
      usage
      exit 1
      ;;
   *) # No more options
      break
      ;;
   esac
done

if [ "$#" -ne 1 ] ; then
   echo "Error: Missing or incorrect arguments."
   usage
   exit 1
fi

# Save the VMDK filename. This is expected end in *-flat.vmdk.
VMDK_FILENAME=$1
# Determine the vmdk file prefix (which is the VM name). We can use that later to look for
# additional disks for the various Edge sizes.
VM_NAME=${VMDK_FILENAME%-flat.vmdk}
echo "VM_NAME=$VM_NAME"
MNTDIR="$TOPDIR/$VM_NAME"
create_directories
mount_vmdk
