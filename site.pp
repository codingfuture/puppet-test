
# WARNING: This will not work with per-environment heira.yaml version 4 any more
# It does lookup only in Global Hiera!
#hiera_include('classes')

# Please make sure "module_data" module is not used as it poisons lookup() processing.
# See https://tickets.puppetlabs.com/browse/PUP-5952 for more details.
lookup('classes', Array[String], 'unique').include
