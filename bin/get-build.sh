#!/bin/bash

BUILD_NUMBER=$1
OVFFILEPREFIX="nsx-edge-"

if [[ $1 =~ ^(ob|sb)-([0-9]*)$ ]]; then
   # Treat it as an official/sandbox build number
   PREFIX=${BASH_REMATCH[1]}
   BUILDNUM=${BASH_REMATCH[2]}
   if [ "$PREFIX" == "ob" ]; then
      PREFIX="bora"
   fi
   TARFILENAME="nsx-edge-ovf-$BUILDNUM.tar.gz"
   URL="http://build-squid.eng.vmware.com/build/mts/release/$PREFIX-$BUILDNUM/publish/$TARFILENAME"
else
   echo "Error: Invalid build number"
   exit 1
fi

wget $URL
if [ $? -ne 0 ]; then
   # Failed to download file. Let's fallback to old tarball name and try once more.
   TARFILENAME="vse-ovf-$BUILDNUM.tar.gz"
   OVFFILEPREFIX="vShieldEdge-"
   URL="http://build-squid.eng.vmware.com/build/mts/release/$PREFIX-$BUILDNUM/publish/$TARFILENAME"
   wget $URL
   if [ $? -ne 0 ]; then
      # Failed again. Bail out!
      echo "ERROR: Failed to download Edge OVF tarball."
      exit 1
   fi
fi

tar -xf $TARFILENAME
chown secureall:secureall $OVFFILEPREFIX*
rm $TARFILENAME
echo "INFO: Success!"
exit 0
