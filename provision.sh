#!/bin/bash

test ! -d modules && librarian-puppet install

skip_dns=${skip_dns:-0}

vagrant up

if test "$skip_dns" != 1; then
    vagrant ssh maint -- sudo /opt/puppetlabs/bin/puppet resource host maint.example.com ip=10.10.1.10
    vagrant ssh maint -- sudo /opt/puppetlabs/bin/puppet resource host puppet.example.com ip=10.10.1.11
    vagrant ssh maint -- sudo /opt/puppetlabs/bin/puppet resource host puppetback.example.com ip=10.10.1.12
fi

for h in maint router puppet puppetback; do
        echo "Provisioning $h"
        
        if test "$skip_dns" != 1; then
            if test $h = 'maint';  then
                vagrant ssh $h -c "echo 'nameserver 8.8.8.8' | sudo tee /etc/resolv.conf"
            else
                vagrant ssh $h -c "echo 'nameserver 10.10.1.10' | sudo tee /etc/resolv.conf"
            fi
        fi
        
        vagrant ssh $h -- sudo /opt/puppetlabs/bin/puppet agent --test --trace
        
        if test $h = 'puppet'; then
            vagrant ssh $h -- sudo /opt/puppetlabs/bin/puppet apply \
                --catalog /opt/puppetlabs/puppet/cache/client_data/catalog/puppet.example.com.json
            vagrant ssh $h -- sudo /bin/systemctl restart cfpostgresql-cfpuppet.service
            vagrant ssh $h -- sudo /opt/puppetlabs/bin/puppet agent --test --trace
            vagrant ssh $h -- sudo /bin/systemctl restart cfpostgresql-cfpuppet.service
        fi
        
        vagrant ssh $h -- sudo /opt/puppetlabs/bin/puppet agent --test --trace
        vagrant ssh maint -- sudo /opt/puppetlabs/bin/puppet agent --test --trace
        vagrant ssh $h -- sudo /opt/puppetlabs/bin/puppet agent --test --trace
        
        if test $h = 'puppetback';  then
            vagrant ssh $h -- sudo /opt/puppetlabs/bin/puppet agent --test --trace
            vagrant ssh puppet -- sudo /opt/puppetlabs/bin/puppet agent --test --trace
            vagrant ssh puppet -- sudo /bin/systemctl restart cfpostgresql-cfpuppet.service
            vagrant ssh $h -- sudo /bin/systemctl stop cfpostgresql-cfpuppet.service
            vagrant ssh $h -- sudo rm -r /db/postgresql_cfpuppet/conf/unclean_state
            vagrant ssh $h -- sudo /opt/puppetlabs/bin/puppet agent --test --trace
        fi
done

for h in web web2 web3; do
    vagrant ssh $h -c "sudo sh -c 'echo -n web >/etc/cflocationpool'"
done

for h in dbclust1 dbclust2 db web web2 web3; do
    if test "$skip_dns" != 1; then
        if test $h = 'maint';  then
            vagrant ssh $h -c "echo 'nameserver 8.8.8.8' | sudo tee /etc/resolv.conf"
        else
            vagrant ssh $h -c "echo 'nameserver 10.10.1.10' | sudo tee /etc/resolv.conf"
        fi
    fi

    echo "Provisioning $h"
    # Initial
    vagrant ssh $h -- sudo /opt/puppetlabs/bin/puppet agent --test --trace
    vagrant ssh maint -- sudo /opt/puppetlabs/bin/puppet agent --test --trace
    # Do facts
    vagrant ssh $h -- sudo /opt/puppetlabs/bin/puppet agent --test --trace
done

for h in maint router puppet puppetback dbclust1 dbclust2 db web web2 web3; do
    echo "Provisioning $h"
    vagrant ssh $h -- sudo /opt/puppetlabs/bin/puppet agent --test --trace
done

vagrant ssh dbclust1 -- sudo /bin/systemctl restart \
    cfpostgresql-pgclust1.service cfpostgresql-pgclust2.service
vagrant ssh dbclust2 -- sudo /bin/systemctl restart \
    cfpostgresql-pgclust1.service cfpostgresql-pgclust2.service
vagrant ssh db -- sudo /bin/systemctl restart \
    cfmysql-mysrv1.service cfmysql-mysrv2.service \
    cfpostgresql-pgclust1.service cfpostgresql-pgclust2.service \
    cfpostgresql-pgsrv1.service
    
vagrant ssh dbclust1 -- sudo rm -f \
    /db/mysql_myclust1/conf/restart_required \
    /db/mysql_myclust2/conf/restart_required
vagrant ssh dbclust2 -- sudo rm -f \
    /db/mysql_myclust1/conf/restart_required \
    /db/mysql_myclust2/conf/restart_required

    
# Final check
for h in maint router puppet puppetback dbclust1 dbclust2 db web web2 web3; do
    echo "Provisioning $h"
    vagrant ssh $h -- sudo /opt/puppetlabs/bin/puppet agent --test --trace
done
