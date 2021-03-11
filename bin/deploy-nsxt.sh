#!/bin/bash
# Helper script to deploy an NSXv Edge VM (compact).
#
VCUSER=administrator@vsphere.local
VCPASS='Admin!23Admin'
#VCPASS='VMwareca$hc0w'
OVFTOOL_BIN=/build/toolchain/lin64/ovftool-4.1.0/ovftool

# Location of the OVF tarball cache directory. Tarballs are downloaded to here
# and this script will check in this directory before downloading the tarball again.
OVF_CACHE_DIR=/tmp/ovf-cache

# Deployment environment config

VCIP=10.20.119.89
VCDATACENTER='Datacenter'
VCCLUSTER='Cluster'
DATASTORE='DatastoreSSD'
RESOURCEPOOL='Transformers'
NETWORK0="Network 0=VM Network"
TARGET="vi://$VCUSER:$VCPASS@$VCIP/$VCDATACENTER/host/$VCCLUSTER/Resources/$RESOURCEPOOL"
URL=
SOURCE=
SIZE="small"
COREDUMP=""
PASSWORD="Admin!23Admin"

trap cleanup EXIT QUIT INT TERM
cleanup()
{
   if [ -d "$TMPDIR" ]; then
      rm -rf $TMPDIR
   fi
}

usage()
{
   options_string="[-s|--size small|medium||large]"
   echo "$0 <local-ovf-filename> <vm-name-prefix>"
   echo "   e.g. $0 $options_string nsx-edge-2.2.0.0.0.7676810.ova edge1"
   echo "        $0 $options_string nsx-edge-2.2.0.0.0.7676810.ovf edge2"
   echo
   echo "$0 <ova-url> <vm-name-prefix>"
   echo "   e.g. $0 $options_string http://build-squid.eng.vmware.com/build/mts/release/bora-7676810/publish/exports/ova/nsx-edge-2.2.0.0.0.7676810.ova edge1"
   echo
   echo "$0 <official-or-sandbox-build-number> <vm-name-prefix>"
   echo "   e.g. $0 $options_string sb-1234567 edge1"
   echo "        $0 $options_string ob-7654321 edge2"
}

while :
do
   case "$1" in
   -s|--size)
      case "$2" in
      small|medium|large)
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
elif [[ $1 =~ ^(ob|sb)-([0-9]*)$ ]]; then
   # Treat it as an official/sandbox build number
   PREFIX=${BASH_REMATCH[1]}
   BUILDNUM=${BASH_REMATCH[2]}
   if [ "$PREFIX" == "ob" ]; then
      PREFIX="bora"
   fi
   #URL="http://build-squid.eng.vmware.com/build/mts/release/$PREFIX-$BUILDNUM/publish/exports/ovf/nsx-edge-3.0.0.0.0.$BUILDNUM.ovf"
   URL="http://build-squid.eng.vmware.com/build/mts/release/$PREFIX-$BUILDNUM/publish/exports/ovf/nsx-edge-2.3.0.0.6.$BUILDNUM.ovf"
   SOURCE=$URL
fi

# Download the ova, if required.
#if [[ $URL =~ ^http(|s):// ]]; then
#   FILENAME=$(basename $URL)
#   TMPDIR=$(mktemp -d /tmp/ovf-XXXXX)
#   wget -P $TMPDIR $URL
#   SOURCE=$TMPDIR/$FILENAME
#fi

if [ -z "$SOURCE" ]; then
   # No idea what you said!
   echo "ERROR: Unable to parse the source URL/Filename"
   usage
   exit 1
fi

VMNAME=$2-$SIZE

$OVFTOOL_BIN \
   --acceptAllEulas \
   --allowAllExtraConfig \
   --noSSLVerify \
   --name="$VMNAME" \
   --datastore=$DATASTORE \
   --diskMode=thin \
   --net:"$NETWORK0" \
   --prop:"is_autonomous_edge=True" \
   --prop:"nsx_cli_passwd_0=$PASSWORD" \
   --prop:"nsx_passwd_0=$PASSWORD" \
   --powerOn \
   "$SOURCE" \
   "$TARGET"


