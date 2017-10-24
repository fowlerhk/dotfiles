#!/bin/bash

if [ $# == 0 ]; then
    echo "Usage: ${0##*/} {PUT|POST|GET} <ip-address> <URL> [xml-file]"
    echo "  e.g: ${0##*/} PUT 10.117.4.140 /edge-4/loadbalancer/config lbConfigAll.xml"
    exit 1
fi

AUTH_ADMIN_DEFAULT="YWRtaW46ZGVmYXVsdA=="
AUTH_ADMIN_VMWARE="YWRtaW46dm13YXJl"

if [ $# == 3 ]; then
    curl -k -H "content-type: application/xml" -H "Authorization: Basic $AUTH_ADMIN_DEFAULT" -X $1 https://$2/api/4.0/edges$3
    echo ""
    exit 0
fi

if [ $# == 4 ]; then
    curl -k -H "content-type: application/xml" -H "Authorization: Basic $AUTH_ADMIN_DEFAULT" -X $1 https://$2/api/4.0/edges$3 -d "`cat $4`"
fi
echo ""
