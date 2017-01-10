#!/bin/bash

vagrant rsync puppet

function check_module() {
    local m=$1
    echo $m
    echo =============================
    vagrant ssh puppet -- sudo /opt/puppetlabs/bin/puppet parser validate /etc/puppetlabs/code/environments/production/$m
    ./update_copyright.sh $m
    puppet-lint -f $m
    metadata-json-lint $m/metadata.json
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
