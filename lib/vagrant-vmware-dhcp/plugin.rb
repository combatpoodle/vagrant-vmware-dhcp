require_relative "action"
require_relative "dhcp"

module VagrantPlugins
  module VagrantVmwareDhcp
    class Plugin < Vagrant.plugin("2")
      name "VagrantVmwareDhcp"
      description <<-DESC
      Adds static private IPs to VMware's DHCP configuration so that your networks behave normally.
      Especially nice on multi-vm environments with Windows.
      DESC

      config(:control_dhcp) do
        Config
      end

      action_hook('DA VMware Network: Configure MAC addresses') do |hook|
        action = Vagrant::Action::Builtin::ConfigValidate
        hook.before(action, VagrantVmwareDhcp::Action::SetMac)
      end

      action_hook('DA VMware Network: Configure dhcp.conf') do |hook|
        if defined?(ActionConfigure)
          # no-op
        elsif Vagrant::Util::Platform.windows? or Vagrant::Util::Platform.linux?
          ActionConfigure = HashiCorp::VagrantVMwareworkstation::Action::Network
        elsif Vagrant::Util::Platform.darwin?
          ActionConfigure = HashiCorp::VagrantVMwarefusion::Action::Network
        end

        hook.after(ActionConfigure, VagrantVmwareDhcp::Action::ConfigDhcp)
      end

      action_hook('DA VMware Network: Prune dhcp.conf') do |hook|
        if defined?(ActionPrune)
          # no-op
        elsif Vagrant::Util::Platform.windows? or Vagrant::Util::Platform.linux?
          ActionPrune = HashiCorp::VagrantVMwareworkstation::Action::Destroy
        elsif Vagrant::Util::Platform.darwin?
          ActionPrune = HashiCorp::VagrantVMwarefusion::Action::Destroy
        end

        hook.before(ActionPrune, VagrantVmwareDhcp::Action::PruneDhcp)
      end

      # action_hook(:init_i18n, :environment_load) { init_i18n }
      # def self.init_i18n
      #   I18n.load_path << File.expand_path("locales/en.yml", VagrantVmwareDhcp.source_root)
      #   I18n.reload!
      # end
    end
  end
end
