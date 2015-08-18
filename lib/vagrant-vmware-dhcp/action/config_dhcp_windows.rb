require "log4r"
require "digest"

# Someone who's had some sleep recently is welcome to come fill in comments here...
module VagrantPlugins
  module VagrantVmwareDhcp
    module Action
      class ConfigDhcpWindows < ConfigDhcp

        protected

        def dhcpd_conf_location(network)
          # Locations from https://pubs.vmware.com/workstation-9/index.jsp?topic=%2Fcom.vmware.ws.using.doc%2FGUID-04D783E1-3AB9-4D98-9891-2C58215905CC.html

          if File.exist?('c:\ProgramData\VMware\vmnetdhcp.conf')
            location = 'C:\ProgramData\VMware\vmnetdhcp.conf'
          elsif File.exist?('C:\Documents and Settings\All Users\Application Data\VMware\vmnetdhcp.conf')
            location = 'C:\Documents and Settings\All Users\Application Data\VMware\vmnetdhcp.conf'              
          end

          @logger.debug("Using dhcpd.conf at #{location}")

          return location
        end

        def prune_dhcpd_conf(network)
          conf_location = dhcpd_conf_location(network)

          mac = network[:mac]

          before = File.open(conf_location).read

          @logger.debug("Before altering, dhcpd.conf content is #{before}")

          after = before.gsub(/^# VAGRANT-BEGIN: #{mac}.*^# VAGRANT-END: #{mac}\s+/m, '')

          File.open(conf_location, "w") { |fd| fd.write(after) }

          after = File.open(conf_location).read
          @logger.debug("After altering, dhcpd.conf content is #{after}")
        end

        def write_dhcpd_conf(network)
          conf_location = dhcpd_conf_location(network)

          section = get_dhcpd_section(network)

          @logger.debug("DHCPD template for interface #{network[:vnet]} is #{section}")

          before = File.open(conf_location).read
          @logger.debug("Before altering, dhcpd.conf content is #{before}")

          after = "#{before}\n\n#{section}\n"

          File.open(conf_location, "w") { |fd| fd.write(after) }

          after = File.open(conf_location).read
          @logger.debug("After, dhcpd.conf content is #{after}")
        end

        def trigger_dhcpd_update
          # This is non-authoritative, but is the obvious solution and seems to work.

          stopCommand = [ "NET", "STOP", "VMware DHCP Service" ]
          startCommand = [ "NET", "START", "VMware DHCP Service" ]

          Vagrant::Util::Subprocess.execute(*stopCommand)
          r = Vagrant::Util::Subprocess.execute(*startCommand)

          if r.exit_code != 0
            @env[:ui].error("VMNet dhcp start exited with code #{r.exit_code} and output:\n#{r.stdout.chomp}")
          end

        end
      end
    end
  end
end
