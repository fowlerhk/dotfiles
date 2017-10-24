#!/bin/bash

usage()
{
   echo "Usage:"
   echo "    $0 <build-commit-id> <commit-id>"
   exit 1
}

[ $# -eq 2 ] || usage
git merge-base --is-ancestor $1 $2
if [ $? -eq 1 ]; then
   echo "Commit $2 is in the build"
else
   echo "Commit $2 is NOT in the build"
fi
