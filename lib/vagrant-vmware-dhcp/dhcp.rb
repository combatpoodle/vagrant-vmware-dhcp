module VagrantPlugins
  module VagrantVmwareDhcp
    require_relative 'dhcp_manager/dhcp_manager.rb'
    require_relative 'dhcp_manager/dhcp_manager_darwin.rb'
    require_relative 'dhcp_manager/dhcp_manager_linux.rb'
    require_relative 'dhcp_manager/dhcp_manager_windows.rb'
  end
end
