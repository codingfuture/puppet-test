#!/bin/bash

vagrant up
#vagrant ssh puppet -- sudo service puppetdb restart
#vagrant ssh puppet -- sudo service puppetserver restart
for h in maint router puppet db web; do
        vagrant ssh $h -- sudo /opt/puppetlabs/bin/puppet resource host puppet.example.com ip=10.10.1.11
        vagrant ssh $h -- sudo /opt/puppetlabs/bin/puppet resource host maint.example.com ip=10.10.1.10
        
	while !vagrant ssh $h -- sudo /opt/puppetlabs/bin/puppet agent --test --environment master; do
            sleep 1;
	done
done
