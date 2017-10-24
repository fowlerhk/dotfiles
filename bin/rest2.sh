#!/bin/bash

if [ $# == 0 ]; then
    echo "Usage: ${0##*/} {PUT|POST|GET} <ip-address> <URL> [xml-file]"
    echo "  e.g: ${0##*/} GET 10.117.4.140 /services/ipset/scope/globalroot-0"
    exit 1
fi

AUTH_ADMIN_DEFAULT="YWRtaW46ZGVmYXVsdA=="
AUTH_ADMIN_VMWARE="YWRtaW46dm13YXJl"

if [ $# == 3 ]; then
    curl -i -k -H "content-type: application/xml" -H "Authorization: Basic $AUTH_ADMIN_DEFAULT" -X $1 https://$2/api/2.0$3
    echo ""
    exit 0
fi

if [ $# == 4 ]; then
    curl -i -k -H "content-type: application/xml" -H "Authorization: Basic $AUTH_ADMIN_DEFAULT" -X $1 https://$2/api/2.0$3 -d @$4
fi
echo ""
