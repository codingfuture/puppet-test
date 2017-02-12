#!/bin/bash

function check_module() {
    local m=$1
    echo $m
    echo =============================
    ./update_copyright.sh $m
    puppet parser validate $m
    puppet-lint -f $m
    metadata-json-lint $m/metadata.json
    test -d $m/lib && \
        find $m/lib -name '*.rb' | \
        while read f; do ruby -c $f >/dev/null; done
}

if test -z "$1"; then
    for m in modules/cf*; do
        check_module $m
    done
else
    for m in $@; do
        check_module $m
    done
fi
