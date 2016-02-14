#!/bin/bash

certname=${1:-$(hostname)}
cflocation=$2
cflocationpool=$3
http_proxy=$4

if test "$(id -un)" != 'root'; then
    echo 'This script must run as root'
    exit 1
fi

if test ! -z "$cflocation"; then
    echo -n $cflocation >/etc/cflocation
fi
if test ! -z "$cflocationpool"; then
    echo -n $cflocationpool >/etc/cflocationpool
fi

if test ! -z "$http_proxy"; then
    export http_proxy
    export https_proxy="$http_proxy"
    export HTTP_PROXY="$http_proxy"
    export HTTPS_PROXY="$http_proxy"
fi

echo $certname > /etc/hostname
hostname $certname

if ! which lsb-release | read; then
    apt-get install -y lsb-release
fi


export DEBIAN_FRONTEND=noninteractive

codename=$(lsb_release -cs)

if test -z "$codename"; then
    echo "Failed to detect correct codename"
    exit 1
fi

wget -q https://apt.puppetlabs.com/puppetlabs-release-pc1-${codename}.deb
dpkg -i puppetlabs-release-pc1-${codename}.deb

mkdir -p /etc/puppetlabs/puppet

cat >/etc/puppetlabs/puppet/puppet.conf <<EOF
[main]
environment = master
certname = $certname
server = $certname
environment = production

[master]
vardir = /opt/puppetlabs/server/data/puppetserver
logdir = /var/log/puppetlabs/puppetserver
rundir = /var/run/puppetlabs/puppetserver
pidfile = /var/run/puppetlabs/puppetserver/puppetserver.pid
codedir = /etc/puppetlabs/code

# !!! NOT FOR PRODUCTION !!!
autosign = true

EOF

apt-get update && \
    apt-get install \
        -f -y \
        -o Dpkg::Options::="--force-confold" \
        git \
        puppet-agent \
        puppetserver
    
totalmem=$(( $(grep MemTotal /proc/meminfo | awk '{print $2}') / 1024 ))
psmem=$(( $totalmem / 4 ))
sed -i -e "s/^.*JAVA_ARGS.*$/JAVA_ARGS=\"-Xms${psmem}m -Xmx${psmem}m\"/g" \
    /etc/default/puppetserver

# Setup self
#---
PUPPET=/opt/puppetlabs/bin/puppet
$PUPPET resource service puppetserver ensure=running enable=true
$PUPPET agent --test

# Setup postgres
#---
$PUPPET resource package postgresql ensure=latest
$PUPPET resource package postgresql-contrib ensure=latest
sudo -u postgres createuser -DRS puppetdb
sudo -u postgres psql -c "ALTER USER puppetdb WITH PASSWORD 'puppetdb';"
sudo -u postgres createdb -E UTF8 -O puppetdb puppetdb
sudo -u postgres psql puppetdb -c 'create extension pg_trgm'
for f in /etc/postgresql/*/main/pg_hba.conf; do
    cat >$f <<EOCONF
# TYPE  DATABASE   USER   CIDR-ADDRESS  METHOD
local   all        all                  md5
host    all        all    127.0.0.1/32  md5
host    all        all    ::1/128       md5    
EOCONF
done
sed -i -e "s/^.*shared_buffers.*$/shared_buffers = ${psmem}MB/g" \
    /etc/postgresql/*/main/postgresql.conf

sudo service postgresql restart

# Setup puppet DB
#---
$PUPPET resource package puppetdb ensure=latest
sed -i -e "s/^.*JAVA_ARGS.*$/JAVA_ARGS=\"-Xms${psmem}m -Xmx${psmem}m\"/g" \
    /etc/default/puppetdb
cat >/etc/puppetlabs/puppetdb/conf.d/database.ini <<EOCONF
[database]
classname = org.postgresql.Driver
subprotocol = postgresql
subname = //localhost:5432/puppetdb
username = puppetdb
password = puppetdb
log-slow-statements = 10
EOCONF
$PUPPET resource service puppetdb ensure=running enable=true
service puppetdb restart

# Connect PuppetMaster to PuppetDB
$PUPPET resource package puppetdb-termini ensure=latest
grep $certname /etc/hosts | read || \
    $PUPPET resource host $certname ip=$(/opt/puppetlabs/bin/facter networking.ip)

cat >>/etc/puppetlabs/puppet/puppet.conf <<EOCONF

# puppetdb-related
storeconfigs = true
storeconfigs_backend = puppetdb
reports = store,puppetdb
EOCONF
cat >/etc/puppetlabs/puppet/puppetdb.conf <<EOCONF
[main]
server_urls = https://$certname:8081
EOCONF
cat >/etc/puppetlabs/puppet/routes.yaml <<EOCONF
---
master:
  facts:
    terminus: puppetdb
    cache: yaml
EOCONF

ln -sfn environments/production/hiera.yaml /etc/puppetlabs/code/hiera.yaml 
chown -R puppet:puppet `puppet config print confdir`
systemctl enable puppetdb puppetserver

# r10k
#----
mkdir -p /etc/puppetlabs/r10k/
cat >/etc/puppetlabs/r10k/r10k.yaml <<EOCONF
# The location to use for storing cached Git repos
:cachedir: '/opt/puppetlabs/r10k/cache'

# A list of git repositories to create
:sources:
  :conf:
    remote: '/vagrant'
    basedir: '/etc/puppetlabs/code/environments'
EOCONF

/opt/puppetlabs/puppet/bin/gem install r10k
/opt/puppetlabs/puppet/bin/r10k deploy environment -p
service puppetserver restart
#---
