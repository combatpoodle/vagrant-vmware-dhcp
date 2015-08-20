module VagrantPlugins
  module VagrantVmwareDhcp
    require_relative 'action/set_mac'
    require_relative 'action/config_dhcp'
    require_relative 'action/prune_dhcp'
  end
end
