#!/bin/bash

for h in maint router puppet puppetback dbclust1 dbclust2 db web web2 web3; do
        echo "Syncing date on $h"
        vagrant ssh $h -- sudo cf_ntpdate
done
