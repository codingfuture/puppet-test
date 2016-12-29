#!/bin/bash

if test -z "$1"; then
    echo "Usage: $(basename $0) module path)"
fi

author="Andrey Galkin"
year=$(date +"%Y")

function update_rb_file() {
    update_pp_file $1
}

function update_pp_file() {
    local f=$1
    local ftmp=${f}.tmp
    
    if egrep -q "Copyright [0-9]{4}(-[0-9]{4})? \(c\) $author" $f; then
        awk -i inplace "
        /Copyright $year \(c\) $author/ { print; next }
        /Copyright ([0-9]{4})(-[0-9]{4})? \(c\) $author/ {
            print gensub(/([0-9]{4})(-[0-9]{4})?/, \"\\\\1-$year\", \"g\")
            next
        }
        {print}
        " $f
        return
    fi
    
    cat >$ftmp <<EOT
#
# Copyright $year (c) $author
#

EOT

    cat $f >>$ftmp
    mv $ftmp $f
}

for f in $(find $1/manifests -type f -name '*.pp'); do
    update_pp_file $f
done

if [ -d $1/lib ]; then
    for f in $(find $1/lib -type f -name '*rb'); do
        update_rb_file $f
    done
fi

