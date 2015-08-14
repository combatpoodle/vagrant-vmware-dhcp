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

      action_hook('DA VMWare Network: Configure dhcp.conf') do |hook|
        action = HashiCorp::VagrantVMwarefusion::Action::Network
        hook.after(action, VagrantVmwareDhcp::Action::ConfigDhcp)
      end

      # action_hook(:init_i18n, :environment_load) { init_i18n }
      # def self.init_i18n
      #   I18n.load_path << File.expand_path("locales/en.yml", VagrantVmwareDhcp.source_root)
      #   I18n.reload!
      # end
    end
  end
end
