# Vagrant::Vmware::Dhcp

Vagrant-vmware-dhcp is a Vagrant plugin which enables control of DHCP using VMware's native DHCP server.  When a VM is starting up, vagrant-vmware-dhcp ensures that a MAC address is assigned to each private network interface.  Then it just adds the MAC address and desired IP address to the VMware DHCP server.  When your machine comes online, it can then retrieve its IP normally over DHCP.

## Installation

```bash
vagrant plugin install vagrant-vmware-dhcp
```

## Usage

This plugin will piggy-back on top of your existing Vagrant networking configuration, such that switching from virtualbox to VMware with secondary IP addresses becomes flawless.

To enable the plugin, just install and add `config.control_dhcp.enable = true` to your Vagrantfile.

## Known issues

Some Windows host boxes ship with DHCP blocked.

When switching from Virtualbox to VMware and back, don't forget to ensure that you've cleaned out your subnets from the other provider.

It's commonly the case that VMware will provide broken network cards to client VMs or fall victim to strange issues that can only be solved by:
1. Removing the relevant host network interfaces in VMware's network editor (or Fusion's preferences)
2. Rebooting your computer (kernel modules are involved)
3. Manually creating the correct network interfaces in the vmware network editor or fusion preferences.

Sadly, there do not seem to be any workarounds for these issues currently and they appear to cause problems across all platforms.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/israelshirk/vagrant-vmware-dhcp. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

