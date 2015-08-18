require_relative "action"

module VagrantPlugins
  module VagrantVmwareDhcp
    class Plugin < Vagrant.plugin("2")
      name "VagrantVmwareDhcp"
      description <<-DESC
      Adds static private IPs to VMware's DHCP configuration so that your networks behave normally.
      Especially nice on multi-vm environments with Windows.
      DESC

      action_hook('DA VMWare Network: Configure MAC addresses') do |hook|
        action = Vagrant::Action::Builtin::ConfigValidate
        hook.before(action, VagrantVmwareDhcp::Action::SetMac)
      end

      if Vagrant::Util::Platform.windows?
        ConfigDhcpClass = VagrantVmwareDhcp::Action::ConfigDhcpWindows
        ActionClass = HashiCorp::VagrantVMwaredesktop::Action::Network
      elsif Vagrant::Util::Platform.linux?
        ConfigDhcpClass = VagrantVmwareDhcp::Action::ConfigDhcpLinux
        ActionClass = HashiCorp::VagrantVMwaredesktop::Action::Network
      elsif Vagrant::Util::Platform.darwin?
        ConfigDhcpClass = VagrantVmwareDhcp::Action::ConfigDhcpDarwin
        ActionClass = HashiCorp::VagrantVMwarefusion::Action::Network
      end

      action_hook('DA VMWare Network: Configure dhcp.conf') do |hook|
        hook.after(ActionClass, ConfigDhcpClass)
      end

      # action_hook(:init_i18n, :environment_load) { init_i18n }
      # def self.init_i18n
      #   I18n.load_path << File.expand_path("locales/en.yml", VagrantVmwareDhcp.source_root)
      #   I18n.reload!
      # end
    end
  end
end
