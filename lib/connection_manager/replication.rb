require 'active_support/core_ext/hash/indifferent_access'
module ConnectionManager
  module Replication 
    # Replication methods (replication_method_name, which is the option[:name] for the
    # #replication method) and all their associated connections. The key is the
    # replication_method_name and the value is an array of all the replication_classes
    # the replication_method has access to.
    # 
    # EX: replication_methods[:slaves] => ['Slave1Connection',Slave2Connection]
    def replication_methods
      @replication_methods ||= HashWithIndifferentAccess.new
    end
       
    # Is this class replicated
    def replicated?
      (@replicated == true)
    end
    
    # Builds a class method that returns an ActiveRecord::Relation for use with
    # in ActiveRecord method chaining.
    # 
    # EX: 
    # class MyClass < ActiveRecord::Base
    #   replicated :my_readonly_db, "FooConnection", :method_name => 'slaves'
    #   end
    # end
    #
    # Options:
    # * :name - name of class method to call to access replication, default to slaves
    # * :readonly - forces all results to readonly
    # * :type - the type of replication; :slave or :master, defaults to :slave
    def replicated(*connections)
        @replicated = true
        options = {:name => "slaves"}.merge!(connections.extract_options!)
        options[:type] ||= :slaves
        options[:build_replicants] = true if (options[:build_replicants].blank? && options[:type] == :masters)
        use_database(current_database_name, :table_name => table_name) # make sure the base class has current_database_name set
        connections = connection.replication_keys(options[:type]) if connections.blank?
        set_replications_to_method(connections,options[:name])
        build_repliciation_class_method(options)
        build_query_method_alias_method(options[:name])
        build_repliciation_instance_method(options[:name])
        options[:name]
    end
      
    # Get a connection class name from out replication_methods pool.
    def fetch_replication_method(method_name)
      available_connections = @replication_methods[method_name]
      raise ArgumentError, "No connections found for #{method_name}." if available_connections.blank?
      available_connections.rotate!
      available_connections[0]
    end
    
    private
    # Builds replication connection classes and methods
    def set_replications_to_method(connections,replication_method_name='slaves') 
      raise ArgumentError, "connections could not be found for #{self.name}." if connections.blank?
      connections.each do |to_use| 
        connection_class_name = fetch_connection_class_name(to_use) 
        replication_methods[replication_method_name] ||= []
        replication_methods[replication_method_name] << connection_class_name
      end
      true
    end
    
    def fetch_connection_class_name(to_use) 
      connection_class_name = to_use    
      connection_class_name = fetch_connection_class_name_from_yml_key(connection_class_name) if connection_class_name.to_s.match(/_/)    
      raise ArgumentError, "For #{self.name}, the class #{connection_class_name} could not be found." if connection_class_name.blank?    
      connection_class_name
    end

    def fetch_connection_class_name_from_yml_key(yml_key)
      found = managed_connections[yml_key]
      connection_class_name = nil
      if found     
        connection_class_name = found.first
      else
        raise ArgumentError, "For #{self.name}, a connection class for #{yml_key} could not be found." 
      end
      connection_class_name
    end 
    
    # Adds a class method, that calls #using with the correct connection class name
    # by calling fetch_replication_method with the method name. Adds readonly
    # query method class if replication is specified as readonly.
    def build_repliciation_class_method(options)
      class_eval <<-STR
      class << self
        def #{options[:name]}
          using(fetch_replication_method("#{options[:name]}"))#{options[:readonly] ? '.readonly' : ''}
        end
      end
      STR
    end
       
    # Build a query method with the name of our replication method. This method 
    # uses the relation.klass to fetch the appropriate connection, ensuring the
    # correct connection is used even if the method is already defined by another class.
    # We want to make sure we don't override existing methods in ActiveRecord::QueryMethods
    def build_query_method_alias_method(replication_relation_name)
      unless ActiveRecord::QueryMethods.instance_methods.include?(replication_relation_name.to_sym)
        ActiveRecord::QueryMethods.module_eval do
          define_method replication_relation_name.to_sym do
            using(self.klass.fetch_replication_method(replication_relation_name))
          end
        end
      end
    end
    
    def build_repliciation_instance_method(replication_relation_name)
      define_method replication_relation_name.to_sym do
        using(self.class.fetch_replication_method(replication_relation_name))
      end 
    end
  end
end