require 'vagrant'
require 'vSphere/util/vim_helpers'
require 'vSphere/util/vm_helpers'

module VagrantPlugins
  module VSphere
    autoload :Driver, 'vSphere/driver'

    class Provider < Vagrant.plugin('2', :provider)
      def initialize(machine)
        @machine = machine
      end

      def action(name)
        action_method = "action_#{name}"
        return Action.send(action_method) if Action.respond_to?(action_method)
        nil
      end

      def driver
        return @driver if @driver
        @driver = Driver.new(@machine)
      end

      def ssh_info
        driver.ssh_info
      end

      def state
        driver.state
      end

      def to_s
        id = @machine.id.nil? ? 'new' : @machine.id
        "vSphere (#{id})"
      end
    end
  end
end
