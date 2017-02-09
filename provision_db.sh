#!/bin/bash

cd $(dirname $0)

source provision_common.sh

vagrant destroy $DESTROY_OPTS $DB_HOSTS
puppet_purge $DB_HOSTS

echo "Bootstrapping DB VMs"
for h in $DB_HOSTS; do
    vagrant up $h
    puppet_init $h INIT_ONESHOT=1
done

echo "Provisioning DB VMs"
for i in $(seq 1 2); do
    for h in $DB_HOSTS; do
        puppet_deploy $h || test $i = 1
    done
done

update_maint

echo "Testing CFDB restart pending"
for h in $DB_HOSTS; do
    vagrant ssh $h -- sudo /opt/codingfuture/bin/cfdb_restart_pending
    sleep 5
    puppet_deploy $h
done

echo "Reloading DB VMs"
for h in $DB_HOSTS; do
    reload_vm $h
done
