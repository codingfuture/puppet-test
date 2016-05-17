#!/bin/bash

test ! -d modules && librarian-puppet install
vagrant up
#vagrant ssh puppet -- sudo service puppetdb restart
#vagrant ssh puppet -- sudo service puppetserver restart
for h in maint router puppet puppetback db web dbclust1 dbclust2; do
        echo "Provisioning $h"
        vagrant ssh $h -- sudo /opt/puppetlabs/bin/puppet resource host maint.example.com ip=10.10.1.10
        vagrant ssh $h -- sudo /opt/puppetlabs/bin/puppet resource host puppet.example.com ip=10.10.1.11
        vagrant ssh $h -- sudo /opt/puppetlabs/bin/puppet resource host puppetback.example.com ip=10.10.1.12
        
	while ! vagrant ssh $h -- sudo /opt/puppetlabs/bin/puppet agent --test; do
            sleep 1;
	done
done
