require 'vagrant'

module VagrantPlugins
  module VSphere
    class Provider < Vagrant.plugin('2', :provider)
      def initialize(machine)
        @machine = machine
        @driver = nil
      end

      def action(name)
        action_method = "action_#{name}"
        return Action.send(action_method) if Action.respond_to?(action_method)
        nil
      end

      def driver
        puts "driver requested"
        return @driver if @driver
        @driver = Driver.new(@machine)
      end

      def ssh_info
        puts "ssh_info requested"
        driver.ssh_info
      end

      def state
        puts "state requested"
        driver.state
      end

      def to_s
        id = @machine.id.nil? ? 'new' : @machine.id
        "vSphere (#{id})"
      end
    end
  end
end
