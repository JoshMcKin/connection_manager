require 'active_support/core_ext/hash/indifferent_access'
module ConnectionManager
  module Replication 
    
    # Replication methods (replication_method_name, which is the option[:name] for the
    # #replication method) and all thier associated connections. The key is the
    # replication_method_name and the value is an array of all the replication_classes
    # the replication_method has access to.
    # 
    # EX: replication_methods[:slaves] => ['Slave1Connection',Slave2Connection]
    def replication_methods
      @replication_methods ||= HashWithIndifferentAccess.new
    end
    
    def replicant_classes
      @replicant_classes ||= HashWithIndifferentAccess.new
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
    # * :using - list of connections to use; can be database.yml key or the name of the connection class --- DEPRECIATED
    # * A Block may be passed that will be called on each of the newly created child classes  
    def replicated(*connections)
      @replicated = true
      options = {:name => "slaves"}.merge!(connections.extract_options!)
      options[:type] ||= :slaves
      options[:build_replicants] = true if (options[:build_replicants].blank? && options[:type] == :masters)
      if options[:using]
        connections = options[:using] 
        warn "[DEPRECATION] :using option is deprecated.  Please list replication connections instead. EX: replicated :slave_connection,'OtherSlaveConnectionChild', :name => 'my_slaves'."
      end
      
      # Just incase its blank. Should be formally set by using connection class or at the model manually
      self.table_name_prefix = "#{database_name}." if self.table_name_prefix.blank?
      
      connections = connection.replication_keys(options[:type]) if connections.blank?
      set_replications_to_method(connections,options[:name])
      build_repliciation_class_method(options)
      build_replication_association_class(options)
      build_query_method_alias_method(options[:name])
      build_repliciation_instance_method(options[:name])
      options[:name]
    end
      
    
    # Get a connection class name from out replication_methods pool
    # could add mutex but not sure blocking is with it.
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
    
    # Builds a class within the model with the name of replication method. Use this
    # class as the :class_name options for associations when it is nesseccary to
    # ensure eager loading uses a replication connection.
    # 
    # EX:
    # 
    #   class Foo < ActiveRecord::Base
    #     belongs_to :user
    #     replicated # use default name .slaves
    #   end
    #   
    #   class MyClass < ActiveRecord::Base
    #     has_many :foos
    #     has_many :foo_slaves, :class_name => 'Foo::Slaves'
    #     replicated
    #   end
    #   
    #   a = MyClass.include(:foo_slaves).first
    #   a.foo_slaves => [<Foo::Slave1ConnectionDup...>,<Foo::Slave1ConnectionDup...>...]
    def build_replication_association_class(options)
      class_eval <<-STR
        class #{options[:name].titleize}
          class << self
            def method_missing(name, *args)
              #{self.name}.#{options[:name]}.klass.send(name, *args)
            end
          end
        end
      STR
    end
       
    # Build a query method with the name of our replicaiton method. This method 
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