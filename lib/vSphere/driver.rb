require 'rbvmomi'
require 'vSphere/util/vim_helpers'
require 'vSphere/util/vm_helpers'

module VagrantPlugins
  	module VSphere
    	class Driver
				include Util::VimHelpers
				include Util::VmHelpers

				attr_reader :machine

				def initialize(machine)
					 @machine = machine
				end

				def connection
					raise "connection be called from a code block!" if !block_given?
					begin
						config = @machine.provider_config

						conn = RbVmomi::VIM.connect host: config.host,
																							 user: config.user, password: config.password,
																							 insecure: config.insecure, proxyHost: config.proxy_host,
																							 proxyPort: config.proxy_port

						yield conn
						rescue
							raise
						ensure
							conn.close if conn
					end
				end

				def ssh_info
					return nil if @machine.id.nil?

					connection do |conn|
						vm = get_vm_by_uuid conn, @machine
						return nil if vm.nil?

						ip_address = filter_guest_nic(vm, @machine)
						return nil if ip_address.nil? || ip_address.empty?
						{
								host: ip_address,
								port: 22
						}
					end
				end

				def state
					return :not_created if @machine.id.nil?

					connection do |conn|
						vm = get_vm_by_uuid conn, @machine

						return :not_created if vm.nil?
					end

					if powered_on?
						:running
					else
						# If the VM is powered off or suspended, we consider it to be powered off. A power on command will either turn on or resume the VM
						:poweroff
					end
				end

				def power_on_vm
					return nil if @machine.id.nil?

					connection do |conn|
						vm = get_vm_by_uuid conn, @machine
						vm.PowerOnVM_Task.wait_for_completion
					end
				end

				def power_off_vm
					return nil if @machine.id.nil?

					connection do |conn|
						vm = get_vm_by_uuid conn, @machine
						vm.PowerOffVM_Task.wait_for_completion
					end
				end

				def get_vm_state
					return nil if @machine.id.nil?

					connection do |conn|
						vm = get_vm_by_uuid conn, @machine
						vm.runtime.powerState
					end
				end

				def powered_on?
					return nil if @machine.id.nil?
					get_vm_state.eql?(Util::VmState::POWERED_ON)
				end

				def powered_off?
					return nil if @machine.id.nil?
					get_vm_state.eql?(Util::VmState::POWERED_OFF)
				end

				def suspended?
					return nil if @machine.id.nil?
					get_vm_state.eql?(Util::VmState::SUSPENDED)
				end

				def destroy
					return nil if @machine.id.nil?
					return nil unless is_created

					connection do |conn|
						vm = get_vm_by_uuid conn, @machine
						vm.Destroy_Task.wait_for_completion
					end
				end

				def is_created
					return false if @machine.id.nil?

					connection do |conn|
						vm = get_vm_by_uuid conn, @machine
						return false if vm.nil?
					end

					true
				end

				def is_running
					state == :running
				end

				def snapshot_list
					return nil if @machine.id.nil?

					connection do |conn|
						vm = get_vm_by_uuid conn, @machine
						enumerate_snapshots(vm).map(&:name)
					end
				end

				def delete_snapshot(snapshot_name)
					return nil if @machine.id.nil?

					connection do |conn|
						vm = get_vm_by_uuid conn, @machine
						delete_snapshot(vm, snapshot_name)
					end
				end

				def restore_snapshot(snapshot_name)
					return nil if @machine.id.nil?

					connection do |conn|
						vm = get_vm_by_uuid conn, @machine
						restore_snapshot(vm, snapshot_name)
					end
				end

				def create_snapshot(snapshot_name)
					return nil if @machine.id.nil?

					connection do |conn|
						vm = get_vm_by_uuid conn, @machine
						create_snapshot(vm, snapshot_name)
					end
				end

				private
				def filter_guest_nic(vm, machine)
					return vm.guest.ipAddress unless machine.provider_config.real_nic_ip
					ip_addresses = vm.guest.net.select { |g| g.deviceConfigId > 0 }.map { |g| g.ipAddress[0] }
					fail Errors::VSphereError.new, :'multiple_interface_with_real_nic_ip_set' if ip_addresses.size > 1
					ip_addresses.first
				end
    	end
	end
end