#!/bin/bash

vagrant rsync puppet puppetback

for h in dbclust1 dbclust2 db; do
        echo "Provisioning $h"
        vagrant ssh $h -- sudo /opt/puppetlabs/bin/puppet agent --test --trace
done
