require "connection_manager/version"

module ConnectionManager
  require 'active_record'
  require 'active_support'
  require 'connection_manager/helpers/abstract_adapter_helper'
  require 'connection_manager/helpers/connection_helpers'
  require 'connection_manager/connections'
  require 'connection_manager/associations'
  require 'connection_manager/shards'  
  require 'connection_manager/replication'
  require 'connection_manager/method_recorder'
  require 'connection_manager/connection_manager_railtie' if defined?(Rails) 
  
  # Patches
  require 'connection_manager/patches/cross_schema_patch.rb' if (ActiveRecord::VERSION::MAJOR == 3 && ActiveRecord::VERSION::MINOR == 0)
  
  # Helpers
  ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:include,(ConnectionManager::AbstractAdapterHelper))
  ActiveRecord::Base.extend(ConnectionManager::ConnectionHelpers)  
  
  # Funcationality
  ActiveRecord::Base.extend(ConnectionManager::Associations) 
  ActiveRecord::Base.extend(ConnectionManager::Replication)
  ActiveRecord::Base.extend(ConnectionManager::Shards)
end

