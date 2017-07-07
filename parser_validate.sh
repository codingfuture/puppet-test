#!/bin/bash

eval "$(cid tool env gem | sed 's/^/export /g')"
export GEM_SPEC_CACHE=$GEM_HOME/specs

for t in puppet puppet-lint metadata-json-lint; do
    if ! which $t >/dev/null; then
        cid tool exec gem -- install $t
    fi
done

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
