forge 'https://forgeapi.puppetlabs.com'

PUPPETFILE_LOAD = File.expand_path( '../Puppetfile.local', __FILE__ )

if File.exists? PUPPETFILE_LOAD
    eval(File.read(PUPPETFILE_LOAD)) 
elsif !ENV['PUPPETFILE_USE_GIT']
    mod 'codingfuture/cfauth'
    mod 'codingfuture/cfdb'
    mod 'codingfuture/cffirehol'
    mod 'codingfuture/cfnetwork'
    mod 'codingfuture/cfpuppetserver'
    mod 'codingfuture/cfsystem'
    mod 'codingfuture/cftotalcontrol'
    mod 'codingfuture/cfweb'
else
    mod 'codingfuture/cfauth',
        :git => "https://github.com/codingfuture/puppet-cfauth",
        :ref => 'master'
    mod 'codingfuture/cfdb',
        :git => "https://github.com/codingfuture/puppet-cfdb",
        :ref => 'master'
    mod 'codingfuture/cffirehol',
        :git => "https://github.com/codingfuture/puppet-cffirehol",
        :ref => 'master'
    mod 'codingfuture/cfnetwork',
        :git => "https://github.com/codingfuture/puppet-cfnetwork",
        :ref => 'master'
    mod 'codingfuture/cfpuppetserver',
        :git => "https://github.com/codingfuture/puppet-cfpuppetserver",
        :ref => 'master'
    mod 'codingfuture/cfsystem',
        :git => "https://github.com/codingfuture/puppet-cfsystem",
        :ref => 'master'
    mod 'codingfuture/cftotalcontrol',
        :git => "https://github.com/codingfuture/puppet-cftotalcontrol",
        :ref => 'master'
    mod 'codingfuture/cfweb',
        :git => "https://github.com/codingfuture/puppet-cfweb",
        :ref => 'master'
end
