#!/bin/bash

if [ "$1" != 'skip_maint' ]; then
    echo "Syncing date on maint"
    vagrant ssh maint -- sudo cf_ntpdate
fi

for h in router puppet puppetback dbclust1 dbclust2 db web web2 web3; do
        echo "Syncing date on $h"
        vagrant ssh $h -- sudo cf_ntpdate
done
