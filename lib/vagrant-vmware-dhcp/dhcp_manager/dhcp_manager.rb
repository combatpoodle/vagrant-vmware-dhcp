require "log4r"
require "digest"

# Someone who's had some sleep recently is welcome to come fill in comments here...
module VagrantPlugins
  module VagrantVmwareDhcp
    class DhcpManager

      def initialize(ui, logger, machine)
        @ui = ui
        @logger = logger
        @machine = machine
        @network_map = make_network_map(machine)
      end

      def prune()
        @network_map.each {
          |mac, network|

          prune_configuration(network)
        }

        reload_configuration
      end

      def configure()
        @network_map.each {
          |mac, network|

          @ui.info("Configuring DHCP for #{network[:ip]} on #{network[:vnet]}")

          write_configuration(network)
        }

        @ui.info("DHCP Configured")
      end

      def reload()
        @ui.info("Reloading DHCP Configuration")
        reload_configuration
      end

      protected

      def template_machine_definition(network)
        netname = [network[:vnet], network[:ip].gsub(/\./, '_')].join('_')

        output = Vagrant::Util::TemplateRenderer.render('dhcpd_static',
                                         mac: network[:mac],
                                         ip: network[:ip],
                                         vnet: network[:vnet],
                                         name: netname,
                                         template_root: VagrantPlugins::VagrantVmwareDhcp.source_root().join("templates")
                                         )

        @logger.debug("DHCPD template for interface #{network[:vnet]} is #{output}")

        return output
      end

      private

      def make_network_map(machine)
        vmx_networks = retrieve_vmx_network_settings(machine)

        vm_networks = machine.config.vm.networks.select { |vm_network| vm_network[0] == :private_network and vm_network[1][:ip] and vm_network[1][:mac] }

        network_map = {}

        vm_networks.each { |vm_network|
          mac = vm_network[1][ :mac ]
          mac = mac.scan(/.{2}/).join(":")

          if not vmx_networks.has_key?(mac)
            @logger.error("Missing VMX network configuration for vm_network #{vm_network}")
            next
          end

          network_map[mac] = { :ip => vm_network[1][:ip], :vnet => vmx_networks[mac]["vnet"], :mac => mac }
        }

        @logger.debug("After mutating, network_map is #{network_map}")

        network_map
      end

      def retrieve_vmx_network_settings(machine)
        vmx_networks = {}

        File.open(machine.provider.driver.vmx_path).each_line {
          |line|

          matches = /^(ethernet\d+\.)(.+?)\s*=\s*"?(.*?)"?\s*$/.match(line)

          if not matches
            next
          end

          adapter_name = matches[1]
          adapter_property = matches[2]
          property_value = matches[3]

          if not vmx_networks.has_key?(adapter_name)
            vmx_networks[adapter_name] = {}
          end

          vmx_networks[adapter_name][adapter_property] = property_value
        }

        vmx_networks_by_mac = {}

        vmx_networks.each {
          |adapter_name, properties|

          if not properties.has_key?("address") or not properties.has_key?("vnet")
            next
          end

          vmx_networks_by_mac[ properties['address'] ] = properties
        }

        @logger.debug("After retrieval vmx_networks_by_mac is #{vmx_networks_by_mac}")

        vmx_networks_by_mac
      end

    end
  end
end