module AutoNetwork
  module Action
    require 'vagrant-vmware-dhcp/action/set_mac'
    require 'vagrant-vmware-dhcp/action/config_dhcp'
    require 'vagrant-vmware-dhcp/action/config_dhcp_darwin'
    require 'vagrant-vmware-dhcp/action/config_dhcp_linux'
    require 'vagrant-vmware-dhcp/action/config_dhcp_windows'
  end
end
