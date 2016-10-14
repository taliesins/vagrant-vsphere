require 'rbvmomi'

module VagrantPlugins
  	module VSphere
    	class Driver
    		@@connection = nil

			def initialize(uuid)
				 @uuid = uuid
			end

			def finalize
				close_connection
			end

			def connection
				return @@connection if @@connection

				config = env[:machine].provider_config

				@@connection  = RbVmomi::VIM.connect host: config.host,
					user: config.user, password: config.password,
					insecure: config.insecure, proxyHost: config.proxy_host,
					proxyPort: config.proxy_port
			end

			def close_connection
				if @@connection 
					@@connection.close 
					@@connection = nil
				end
			end
    	end
	end
end