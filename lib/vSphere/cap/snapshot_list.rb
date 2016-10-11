module VagrantPlugins
  module VSphere
    module Cap
      module SnapshotList
        @@lock = Mutex.new

        # Returns a list of the snapshots that are taken on this machine.
        #
        # @return [Array<String>] Snapshot Name
        def self.snapshot_list(machine)

          @@lock.synchronize do
            lock_key = Digest::MD5.hexdigest(machine.box.name)
            machine.env.lock(lock_key, retry: true) do
              env = machine.action(:snapshot_list)
              return env[:machine_snapshot_list]
            end
          end
        end
      end
    end
  end
end
