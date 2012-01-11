require "connection_manager/version"

module ConnectionManager
  require 'active_record'
  require 'connection_manager/connections'
  require 'connection_manager/associations'
  require 'connection_manager/secondary_connection_builder'
  require 'connection_manager/method_recorder'
  require 'connection_manager/connection_manager_railtie' if defined?(Rails) 
    
  ActiveRecord::Base.extend(ConnectionManager::Associations) 
  ActiveRecord::Base.extend(ConnectionManager::SecondaryConnectionBuilder)
  
  require 'connection_manager/cross_schema_patch.rb' if (ActiveRecord::VERSION::MAJOR == 3 && ActiveRecord::VERSION::MINOR == 0)
end

