require "log4r"
require "digest"

# Someone who's had some sleep recently is welcome to come fill in comments here...
module VagrantPlugins
  module VagrantVmwareDhcp
    module Action
      class ConfigDhcp
        def initialize(app, env)
          @app    = app
          @env    = env
          @logger = Log4r::Logger.new("vagrant::plugins::vagrant-vmware-dhcp::config_dhcp")
        end

        def call(env)
          @env = env

          if @env[:machine]
            @logger.info("In config_dhcp provider_name is #{@env[:machine].provider_name}")

            # or env[:machine].provider_name == :vmware_desktop
            if @env[:machine].provider_name == :vmware_fusion
              configure_dhcp
            end
          end

          @app.call(@env)
        end

        private

        def configure_dhcp
          machine = @env[:machine]

          vmx_networks = retrieve_vmx_network_settings(machine)

          @logger.debug("After retrieval vmx_networks are #{vmx_networks}")

          network_map = make_network_map(machine, vmx_networks)

          @logger.debug("After retrieval network_map is #{network_map}")

          apply_static_dhcp_config(machine, network_map)
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

          vmx_networks_by_mac
        end

        def make_network_map(machine, vmx_networks)
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

          network_map
        end

        def guess_dhcpd_conf_location(network)
          @logger.debug("Using dhcpd.conf at #{network[:vnet]}")
          location = "/Library/Preferences/VMware Fusion/#{network[:vnet]}/dhcpd.conf"
          return location
        end

        def apply_static_dhcp_config(machine, network_map)

          network_map.each {
            |mac, network|

            @env[:ui].info("Configuring DHCP for #{network[:ip]} on #{network[:vnet]}")

            prune_dhcpd_conf(network)
            write_dhcpd_conf(network)
          }

          trigger_dhcpd_update

          @env[:ui].info("DHCP Configured")

        end

        def prune_dhcpd_conf(network)
          conf_location = guess_dhcpd_conf_location(network)
          escaped_conf_location = Vagrant::Util::ShellQuote.escape(conf_location, "'")

          mac = network[:mac]

          command = []
          command << "sudo" if !File.writable?(conf_location)
          command += [
            "sed", "-E", "-e",
            "/^# VAGRANT-BEGIN: #{mac}/," +
            "/^# VAGRANT-END: #{mac}/ d",
            "-ibak",
            conf_location
          ]

          system(*command)
        end

        def write_dhcpd_conf(network)
          conf_location = guess_dhcpd_conf_location(network)
          escaped_conf_location = Vagrant::Util::ShellQuote.escape(conf_location, "'")

          sudo_command = ""
          sudo_command = "sudo " if !File.writable?(conf_location)

          netname = [network[:vnet], network[:ip].gsub(/\./, '_')].join('_')

          output = Vagrant::Util::TemplateRenderer.render('dhcpd_static',
                                           mac: network[:mac],
                                           ip: network[:ip],
                                           vnet: network[:vnet],
                                           name: netname,
                                           template_root: VagrantPlugins::VagrantVmwareDhcp.source_root().join("templates")
                                           )

          @logger.debug("DHCPD template for interface #{network[:vnet]} is #{output}")

          before = File.open(conf_location).read
          @logger.debug("Before altering, dhcpd.conf content is #{before}")

          output.split("\n").each do |line|
            line = Vagrant::Util::ShellQuote.escape(line, "'")
            system(%Q[echo '#{line}' | #{sudo_command}tee -a '#{escaped_conf_location}' >/dev/null])
          end

          after = File.open(conf_location).read
          @logger.debug("After, dhcpd.conf content is #{after}")
        end

        def trigger_dhcpd_update
          # Per http://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=1026510

          vmnet_cli = "/Applications/VMware Fusion.app/Contents/Library/vmnet-cli"

          configureCommand = [ "sudo", vmnet_cli, "--configure" ].flatten
          stopCommand      = [ "sudo", vmnet_cli, "--stop" ].flatten
          startCommand     = [ "sudo", vmnet_cli, "--start" ].flatten
          statusCommand    = [ "sudo", vmnet_cli, "--status" ].flatten

          Vagrant::Util::Subprocess.execute(*configureCommand)
          Vagrant::Util::Subprocess.execute(*stopCommand)
          Vagrant::Util::Subprocess.execute(*startCommand)
          r = Vagrant::Util::Subprocess.execute(*statusCommand)

          if r.exit_code != 0
            @env[:ui].error("VMNet status exited with code #{r.exit_code} and output:\n#{r.stdout.chomp}")
          end

        end

      end
    end
  end
end
