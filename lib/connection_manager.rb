require "connection_manager/version"

module ConnectionManager
  require 'active_record'
  require 'connection_manager/connections'
  require 'connection_manager/associations'
  require 'connection_manager/replication_builder'
  require 'connection_manager/connection_manager_railtie.rb' if defined?(Rails)  
end

