require "connection_manager/version"

module ConnectionManager
  require 'active_record'
  require 'active_support'
  require 'connection_manager/helpers/abstract_adapter_helper'
  require 'connection_manager/connection_builder'
  require 'connection_manager/helpers/connection_helpers' 
  require 'connection_manager/using'
  require 'connection_manager/shards'  
  require 'connection_manager/replication'
  require 'connection_manager/patches/cross_schema_patch'
  require 'connection_manager/connection_manager_railtie' if defined?(Rails)
    
  ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:include,(ConnectionManager::AbstractAdapterHelper))
  ActiveRecord::Base.extend(ConnectionManager::ConnectionHelpers) 
  ActiveRecord::Base.extend(ConnectionManager::ConnectionBuilder)
  ActiveRecord::Base.extend(ConnectionManager::Replication)
  ActiveRecord::Base.extend(ConnectionManager::Shards)
  
  ActiveSupport.on_load(:active_record) do
    ActiveRecord::Base.build_connection_classes
  end

  def self.logger
    @logger ||= ActiveRecord::Base.logger
  end
end

