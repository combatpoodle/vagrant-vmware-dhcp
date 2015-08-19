require_relative "action"

module VagrantPlugins
  module VagrantVmwareDhcp
    class Config < Vagrant.plugin(2, :config)
      attr_accessor :enable

      def initialize
        @enable = false
      end

      def finalize!
        if @enable != true
          @enable = false
        end
      end
    end
  end
end
