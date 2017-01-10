#!/bin/bash

set -ex

cd $(dirname $0)

./provision_puppetserver.sh
./provision_db.sh
./provision_web.sh
