#!/bin/bash
# Helper script to deploy an NSXv Edge VM (compact).
#
VCUSER=administrator@vsphere.local
VCPASS='Admin!23Admin'
OVFTOOL_BIN=/build/toolchain/lin64/ovftool-4.1.0/ovftool

# Location of the OVF tarball cache directory. Tarballs are downloaded to here
# and this script will check in this directory before downloading the tarball again.
OVF_CACHE_DIR=/tmp/ovf-cache

# Deployment environment config

VCIP=10.20.119.89
VCDATACENTER='Datacenter'
VCCLUSTER='Cluster'
DATASTORE=Datastore
NETWORK="--net:vnic1=VM Network"
TARGET="vi://$VCUSER:$VCPASS@$VCIP/$VCDATACENTER/host/$VCCLUSTER/"
URL=
SOURCE=
SIZE="compact"
COREDUMP=""
POWERON="--powerOn"

trap cleanup EXIT QUIT INT TERM
cleanup()
{
   if [ -d "$TMPDIR" ]; then
      rm -rf $TMPDIR
   fi
}

usage()
{
   options_string="[-s|--size compact|large|qlarge|xlarge] [-c|--coredump]"
   echo "$0 <local-ovf-filename> <vm-name-prefix>"
   echo "   e.g. $0 $options_string nsx-edge-compact.ovf edge-test1"
   echo
   echo "$0 <local-ovf-tarball-filename> <vm-name-prefix>"
   echo "   e.g. $0 $options_string nsx-edge-ovf-1234567.tar.gz edge-test1"
   echo
   echo "$0 <ovf-tarball-url> <vm-name-prefix>"
   echo "   e.g. $0 $options_string http://build-squid.eng.vmware.com/build/mts/release/sb-7957027/publish/nsx-edge-ovf-7957027.tar.gz edge-test1"
   echo
   echo "$0 <official-or-sandbox-build-number> <vm-name-prefix>"
   echo "   e.g. $0 $options_string sb-1234567 edge-test1"
   echo "        $0 $options_string ob-7654321 edge-test1"
}

while :
do
   case "$1" in
   -s|--size)
      case "$2" in
      compact|large|quadlarge|xlarge)
         SIZE="$2"
         ;;
      *)
         echo "Error: Unknown size: $2" >&2
         usage
         exit 1
         ;;
      esac
      shift 2
      ;;
   -c|--coredump)
      COREDUMP="-coredump"
      shift 1
      ;;
   -p)
      POWERON=""
      shift 1
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

if [ "$#" -ne 2 ]; then
   usage
   exit 1
fi

if [[ $1 =~ .*\.ovf ]] && [ -e "$1" ]; then
   # Treat as a local OVF filename
   SOURCE=$1
elif [[ $1 =~ .*\.ova ]] && [ -e "$1" ]; then
   # Treat as a local OVA filename
   SOURCE=$1
elif [[ $1 =~ .*\.(tar\.gz|tgz) ]] && [ -e "$1" ]; then
   # Treat as a local ovf tarball
   URL=$1
   TMPDIR=$(mktemp -d /tmp/ovf-XXXXX)
   tar -xf $1 -C $TMPDIR
   SOURCE=$TMPDIR/nsx-edge-$SIZE$COREDUMP.ovf
   if [ ! -e $SOURCE ]; then
      SOURCE=$TMPDIR/vShieldEdge-$SIZE$COREDUMP.ovf
      if [ ! -e $SOURCE ]; then
         echo "Invalid OVF tarball. OVF file not found inside!"
         usage
         exit 1
      fi
   fi
elif [[ $1 =~ ^(ob|sb)-([0-9]*)$ ]]; then
   # Treat it as an official/sandbox build number
   PREFIX=${BASH_REMATCH[1]}
   BUILDNUM=${BASH_REMATCH[2]}
   if [ "$PREFIX" == "ob" ]; then
      PREFIX="bora"
   fi
   URL="http://build-squid.eng.vmware.com/build/mts/release/$PREFIX-$BUILDNUM/publish/nsx-edge-ovf-$BUILDNUM.tar.gz"
elif [[ $1 =~ ^http(|s):.*\.tar\.gz ]]; then
   # Treat as a ovf tarball URL
   URL=$1
fi

# Download and extract the ovf tarball, if required.
if [[ $URL =~ ^http(|s):// ]]; then
   TMPDIR=$(mktemp -d /tmp/ovf-XXXXX)
   FILENAME=$(basename $URL)
   SOURCE=$TMPDIR/nsx-edge-$SIZE$COREDUMP.ovf
   wget -P $TMPDIR $URL
   if [ $? -ne 0 ]; then
      # Fallback and try again using the older tarball name.
      URL="http://build-squid.eng.vmware.com/build/mts/release/$PREFIX-$BUILDNUM/publish/vse-ovf-$BUILDNUM.tar.gz"
      FILENAME=$(basename $URL)
      SOURCE=$TMPDIR/vShieldEdge-$SIZE$COREDUMP.ovf
      wget -P $TMPDIR $URL
      if [ $? -ne 0 ]; then
         echo "ERROR: Failed to download Edge OVF tarball."
         exit 1
      fi
   fi
   tar -xf $TMPDIR/$FILENAME -C $TMPDIR
fi

if [ -z "$SOURCE" ]; then
   # No idea what you said!
   echo "ERROR: Unable to parse the source URL/Filename"
   usage
   exit 1
fi

VMNAME=$2-$SIZE$COREDUMP

$OVFTOOL_BIN \
   --acceptAllEulas \
   --allowAllExtraConfig \
   --noSSLVerify \
   --name="$VMNAME" \
   --datastore=$DATASTORE \
   --net:vnic1="VM Network" \
   $POWERON \
   "$SOURCE" \
   "$TARGET"


