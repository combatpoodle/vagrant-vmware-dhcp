require "pathname"
require "vagrant-vmware-dhcp/plugin"

module VagrantPlugins
  module VagrantVmwareDhcp
    lib_path = Pathname.new(File.expand_path("../vagrant-vmware-dhcp", __FILE__))
    autoload :Action,      lib_path.join("action")
    autoload :Config,      lib_path.join("config")

    def self.source_root
      @source_root ||= Pathname.new(File.expand_path("../../", __FILE__))
    end
  end
end