require "log4r"
require "digest"

# Someone who's had some sleep recently is welcome to come fill in comments here...
module VagrantPlugins
  module VagrantVmwareDhcp
    module Action
      class ConfigDhcpLinux < ConfigDhcp

        protected

        def dhcpd_conf_location(network)
          # Locations from https://pubs.vmware.com/workstation-9/index.jsp?topic=%2Fcom.vmware.ws.using.doc%2FGUID-04D783E1-3AB9-4D98-9891-2C58215905CC.html

          location = "/etc/vmware/#{network[:vnet]}/dhcp/dhcp.conf"

          @logger.debug("Using dhcpd.conf at #{location}")

          return location
        end

        def prune_dhcpd_conf(network)
          conf_location = dhcpd_conf_location(network)
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
          conf_location = dhcpd_conf_location(network)
          escaped_conf_location = Vagrant::Util::ShellQuote.escape(conf_location, "'")

          sudo_command = ""
          sudo_command = "sudo " if !File.writable?(conf_location)

          output = get_dhcpd_section(network)

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
