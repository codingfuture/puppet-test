#!/bin/bash

cd $(dirname $0)

git status

for m in modules/cf*; do
    echo
    echo "Module: $m"
    echo "---------------" 
    pushd $m >/dev/null
    git status
    popd >/dev/null
done
