forge 'https://forgeapi.puppetlabs.com'

PUPPETFILE_LOAD = 'Puppetfile.local'

if File.exists? PUPPETFILE_LOAD
    eval(File.read(PUPPETFILE_LOAD)) 
elsif !ENV['PUPPETFILE_USE_GIT']
    mod 'codingfuture/cfnetwork'
    mod 'codingfuture/cffirehol'
    mod 'codingfuture/cfauth'
    mod 'codingfuture/cfsystem'
    mod 'codingfuture/cfpuppetserver'
else
    mod 'codingfuture/cfnetwork',
        :git => "https://github.com/codingfuture/puppet-cfnetwork"
    mod 'codingfuture/cffirehol',
        :git => "https://github.com/codingfuture/puppet-cffirehol"
    mod 'codingfuture/cfauth',
        :git => "https://github.com/codingfuture/puppet-cfauth"
    mod 'codingfuture/cfsystem',
        :git => "https://github.com/codingfuture/puppet-cfsystem"
    mod 'codingfuture/cfpuppetserver',
        :git => "https://github.com/codingfuture/puppet-cfpuppetserver"
end