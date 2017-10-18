#!/bin/bash

set -x

vagrant ssh dbclust2 -- sudo systemctl stop cfmysql-myclust1.service cfmysql-myclust2.service
vagrant ssh db -- sudo systemctl stop cfmysql-myclust1-arb.service cfmysql-myclust2-arb.service

vagrant ssh dbclust1 -- sudo cfdb_myclust1_bootstrap "yes_I_am_sure_I_want_to_bootstrap_cfmysql-myclust1_$(date '+%Y%m%d')" || \
    vagrant ssh dbclust1 -- sudo cfdb_myclust1_bootstrap "yes_I_am_sure_I_want_to_force_bootstrap_of_cfmysql-myclust1_$(date '+%Y%m%d')"
vagrant ssh dbclust1 -- sudo cfdb_myclust2_bootstrap "yes_I_am_sure_I_want_to_bootstrap_cfmysql-myclust2_$(date '+%Y%m%d')" || \
    vagrant ssh dbclust1 -- sudo cfdb_myclust2_bootstrap "yes_I_am_sure_I_want_to_force_bootstrap_of_cfmysql-myclust2_$(date '+%Y%m%d')"

sleep 10

vagrant ssh db -- sudo systemctl start cfmysql-myclust1-arb.service cfmysql-myclust2-arb.service

sleep 5

vagrant ssh dbclust2 -- sudo systemctl start cfmysql-myclust1.service cfmysql-myclust2.service
