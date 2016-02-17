#!/bin/bash

vagrant rsync puppet

for h in maint router puppet db web; do
        echo "Provisioning $h"
        #vagrant ssh $h -- sudo /opt/puppetlabs/bin/puppet resource host puppet.example.com ip=10.10.1.11
        #vagrant ssh $h -- sudo /opt/puppetlabs/bin/puppet resource host maint.example.com ip=10.10.1.10
        vagrant ssh $h -- sudo /opt/puppetlabs/bin/puppet agent --test
done
