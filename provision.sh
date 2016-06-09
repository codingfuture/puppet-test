#!/bin/bash

test ! -d modules && librarian-puppet install
vagrant up

skip_dns=${skip_dns:-0}

#vagrant ssh puppet -- sudo service puppetdb restart
#vagrant ssh puppet -- sudo service puppetserver restart
for i in 1 2 3 4; do
    for h in maint router puppet puppetback db dbclust1 dbclust2 web; do
            echo "Provisioning $h"
            
            if test "$skip_dns" != 1; then
                if test $h = 'maint';  then
                    vagrant ssh $h -- sudo /opt/puppetlabs/bin/puppet resource host maint.example.com ip=10.10.1.10
                    vagrant ssh $h -- sudo /opt/puppetlabs/bin/puppet resource host puppet.example.com ip=10.10.1.11
                    vagrant ssh $h -- sudo /opt/puppetlabs/bin/puppet resource host puppetback.example.com ip=10.10.1.12
                else
                    vagrant ssh $h -c "echo 'nameserver 10.10.1.10' | sudo tee /etc/resolv.conf"
                fi
            fi
            
            vagrant ssh $h -- sudo /opt/puppetlabs/bin/puppet agent --test --trace
            vagrant ssh maint -- sudo /opt/puppetlabs/bin/puppet agent --test --trace
            
            while ! vagrant ssh $h -- sudo /opt/puppetlabs/bin/puppet agent --test --trace; do
                sleep 1;
            done
    done
    
    skip_dns=1
done
