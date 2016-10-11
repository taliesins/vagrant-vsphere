require 'vagrant'

module VagrantPlugins
  module VSphere
    class Provider < Vagrant.plugin('2', :provider)
      @@lock = Mutex.new

      def initialize(machine)
        @machine = machine
      end

      def action(name)
        @@lock.synchronize do
          lock_key = Digest::MD5.hexdigest(@machine.box.name)
          @machine.env.lock(lock_key, retry: true) do
            action_method = "action_#{name}"
            return Action.send(action_method) if Action.respond_to?(action_method)
            return nil
          end
        end
      end

      def ssh_info
        @@lock.synchronize do
          lock_key = Digest::MD5.hexdigest(@machine.box.name)
          @machine.env.lock(lock_key, retry: true) do
            env = @machine.action('get_ssh_info')
            return env[:machine_ssh_info]
          end
        end
      end

      def state
        @@lock.synchronize do
          lock_key = Digest::MD5.hexdigest(@machine.box.name)
          @machine.env.lock(lock_key, retry: true) do
            env = @machine.action('get_state')
            state_id = env[:machine_state_id]

            short = "vagrant_vsphere.states.short_#{state_id}"
            long  = "vagrant_vsphere.states.long_#{state_id}"

            # Return the MachineState object
            return Vagrant::MachineState.new(state_id, short, long)            
          end
        end
      end

      def to_s
        id = @machine.id.nil? ? 'new' : @machine.id
        "vSphere (#{id})"
      end
    end
  end
end
