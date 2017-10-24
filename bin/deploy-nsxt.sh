#!/bin/bash
# Helper script to deploy an NSXv Edge VM (compact).
#
VCUSER=administrator@vsphere.local
VCPASS='VMwareca$hc0w'
OVFTOOL_BIN=/build/toolchain/lin64/ovftool-4.1.0/ovftool

# Location of the OVF tarball cache directory. Tarballs are downloaded to here
# and this script will check in this directory before downloading the tarball again.
OVF_CACHE_DIR=/tmp/ovf-cache

# Deployment environment config

VCIP=10.32.42.242
VCDATACENTER='Datacenter'
VCCLUSTER='Cluster'
VCRESOURCEPOOL='Transformers'
DATASTORE=Datastore
NETWORK="--net:Network 0=VM Network"
TARGET="vi://$VCUSER:$VCPASS@$VCIP/$VCDATACENTER/host/$VCCLUSTER/Resources/$VCRESOURCEPOOL"
URL=
SOURCE=

trap cleanup EXIT QUIT INT TERM
cleanup()
{
   if [ -d "$TMPDIR" ]; then
      rm -rf $TMPDIR
   fi
}

usage()
{
   echo "$0 <local-ovf-filename> <vm-name>"
   echo "   e.g. $0 nsx-edge-2.1.0.0.0.8721940.ovf edge-test1"
   echo
   echo "$0 <ovf-url> <vm-name>"
   echo "   e.g. $0 http://build-squid.eng.vmware.com/build/mts/release/sb-8721940/publish/exports/ovf/nsx-edge-2.1.0.0.0.8721940.ovf edge-test1"
   echo
   echo "$0 <official-or-sandbox-build-number> <vm-name>"
   echo "   e.g. $0 sb-1234567 edge-compact-test1"
   echo "        $0 ob-7654321 edge-compact-test1"
}

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
   SOURCE="http://build-squid.eng.vmware.com/build/mts/release/$PREFIX-$BUILDNUM/publish/exports/ovf/nsx-edge-2.1.0.0.0.$BUILDNUM.ovf"
fi

if [ -z "$SOURCE" ]; then
   # No idea what you said!
   echo "ERROR: Unable to parse the source URL/Filename"
   usage
   exit 1
fi

VMNAME=$2

$OVFTOOL_BIN \
   --acceptAllEulas \
   --allowAllExtraConfig \
   --noSSLVerify \
   --name="$VMNAME" \
   --datastore=$DATASTORE \
   --net:"Network 0=VM Network" \
   --powerOn \
   "$SOURCE" \
   "$TARGET"


