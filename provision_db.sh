#!/bin/bash

cd $(dirname $0)

source provision_common.sh

vagrant destroy -f $DB_HOSTS
puppet_purge $DB_HOSTS

echo "Bootstrapping DB VMs"
for h in $DB_HOSTS; do
    vagrant up $h
    puppet_init $h INIT_ONESHOT=1
done

echo "Provisioning DB VMs"
for i in $(seq 1 3); do
    for h in $DB_HOSTS; do
        puppet_deploy $h || puppet_deploy $h || true
    done
    
    update_maint
done

echo "Completing setup of DB VMs"
for i in $(seq 1 30); do
    hc=$(echo $DB_HOSTS | wc -w)
    for h in $DB_HOSTS; do
        if puppet_deploy $h; then
            hc=$(($hc - 1))
        fi
    done
    
    [ $hc -eq 0 ] && break
done

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
