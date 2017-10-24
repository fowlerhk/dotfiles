#!/bin/bash
# HOW TO USE:
#
# ~# ./resttest.sh PUT 10.117.4.140 /edge-4/loadbalancer/config lbConfigAll.xml

if [ $# == 0 ]; then
    echo "Usage: ${0##*/} {PUT|POST|GET} <ip-address> <URL> [xml-file]"
    echo "  e.g: ${0##*/} PUT 10.117.4.140 /edges/edge-4/loadbalancer/config lbConfigAll.xml"
    exit 1
fi

if [ $# == 3 ]; then
    echo "~# curl -sslv3 -i -k -H \"content-type: application/xml\" -H \"Authorization: Basic YWRtaW46ZGVmYXVsdA==\" -X $1 https://$2/api/3.0$3"
    curl -i -k -H "content-type: application/xml" -H "Authorization: Basic YWRtaW46ZGVmYXVsdA==" -X $1 https://$2/api/3.0$3
    echo ""
    exit 0
fi

if [ $# == 4 ]; then
    echo "~# curl -i -k -H \"content-type: application/xml\" -H \"Authorization: Basic YWRtaW46ZGVmYXVsdA==\" -X $1 https://$2/api/3.0$3 -d @$4"
    curl -i -k -H "content-type: application/xml" -H "Authorization: Basic YWRtaW46ZGVmYXVsdA==" -X $1 https://$2/api/3.0$3 -d @$4
fi
echo ""
