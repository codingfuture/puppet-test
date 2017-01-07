
# WARNING: This will not work with per-environment heira.yaml version 4 any more
# It does lookup only in Global Hiera!
#hiera_include('classes')

# Special hack for Vagrant testing
if $::facts['lsbdistcodename'] == 'jessie' {
    $ifacename = [
        'eth0',
        'eth1',
        'eth2',
        'eth3',
        'eth4',
    ]
} else {
    $ifacename = [
        'enp0s3',
        'enp0s8',
        'enp0s9',
        'enp0s10',
        'enp0s16',
    ]
}

# Please make sure "module_data" module is not used as it poisons lookup() processing.
# See https://tickets.puppetlabs.com/browse/PUP-5952 for more details.
lookup('classes', Array[String], 'unique').include
