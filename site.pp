
# WARNING: This will not work with per-environment heira.yaml version 4 any more
# It does lookup only in external Hiera!
hiera_include('classes')

# Required https://tickets.puppetlabs.com/browse/PUP-5952 to be fixed
#lookup('classes', Array[String], 'unique').include
