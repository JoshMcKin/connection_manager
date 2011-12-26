require "connection_manager/version"

module ConnectionManager
  require 'active_record'
  require 'connection_manager/connections'
  require 'connection_manager/associations'
  require 'connection_manager/secondary_connection_builder'
  require 'connection_manager/method_recorder'
  require 'connection_manager/connection_manager_railtie.rb' if defined?(Rails) 
    
  ActiveRecord::Base.extend(ConnectionManager::Associations) 
  ActiveRecord::Base.extend(ConnectionManager::SecondaryConnectionBuilder)
  
end

