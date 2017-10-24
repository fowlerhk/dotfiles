#!/bin/bash

BUILD_NUMBER=$1

if [[ $1 =~ ^(ob|sb)-([0-9]*)$ ]]; then
   # Treat it as an official/sandbox build number
   PREFIX=${BASH_REMATCH[1]}
   BUILDNUM=${BASH_REMATCH[2]}
   if [ "$PREFIX" == "ob" ]; then
      PREFIX="bora"
   fi
   URL="http://build-squid.eng.vmware.com/build/mts/release/$PREFIX-$BUILDNUM/publish/vse-ovf-$BUILDNUM.tar.gz"
else
   echo "Error: Invalid build number"
   exit 1
fi

wget $URL
tar -xf vse-ovf-$BUILDNUM.tar.gz
chown secureall:secureall vShieldEdge-*
