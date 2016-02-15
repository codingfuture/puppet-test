
## Description

Example configuration and Vagrant VM infrastructure for testing of:
- [cfsystem](https://github.com/codingfuture/puppet-cfsystem)
- [cfauth](https://github.com/codingfuture/puppet-cfauth)
- [cfnetwork](https://github.com/codingfuture/puppet-cfnetwork)
- [cffirehol](https://github.com/codingfuture/puppet-cffirehol)
- [cfppppetserver](https://github.com/codingfuture/puppet-cfppppetserver)

## Vagrant

The provisioning is not so simple:

1. All VMs access internet through `router` VM, but not through the default NAT interface
2. All VMs depend on `maint` for APT proxy, DNS and NTP
3. All VMs depend on `puppet` for true PuppetServer based provisioning

So, what happens:

1. We provision bare VM images with proper network setup
2. Each VM gets Puppet Agent installation
3. `puppet` VM gets also Puppet Server with Puppet DB
4. `maint` VM is provisioned from `puppet`
5. `router` VM is provisioned from `puppet`
6. Rest of VMs are provisioned from `puppet`

Use bundles script for actions above:
```bash
./provision.sh
```