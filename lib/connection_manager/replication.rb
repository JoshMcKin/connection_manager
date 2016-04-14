module ConnectionManager
  module Replication

    # Replication methods (replication_method_name, which is the option[:name] for the
    # #replication method) and all their associated connections. The key is the
    # replication_method_name and the value is an array of all the replication_classes
    # the replication_method has access to.
    #
    # EX: replication_methods[:slaves] => ['Slave1Connection',Slave2Connection]
    attr_accessor :replication_connections

    # Is this class replicated
    def replicated?
      defined?(@replication_connections)
    end

    # Builds a class method that returns an ActiveRecord::Relation for use with
    # in ActiveRecord method chaining.
    #
    # EX:
    # class MyClass < ActiveRecord::Base
    #   replicated :my_readonly_db, "FooConnection",
    #   end
    # end
    #
    # Options:
    # * :name - name of class method to call to access replication, default to slaves
    # * :type - the type of replication; :slaves or :masters, defaults to :slaves
    def replicated(*connections)
      opts = connections.extract_options!
      opts.symbolize_keys!
      opts[:slaves] ||= []
      opts[:masters] ||= []
      opts[:type] ||= :slaves
      opts[opts[:type]] = connections unless connections.empty?
      set_replications_connections(opts)
    end

    def fetch_slave_connection
      fetch_replication_connection(:slaves)
    end

    def fetch_master_connection
      fetch_replication_connection(:masters)
    end

    private

    # Fetch a connection class name from out replication_connections pool.
    # Since any numbers of threads could be attempting to access the replication
    # connections we use sample to get a random connection instead of blocking
    # to rotate the pool on every fetch.
    def fetch_replication_connection(method_name)
      if @replication_connections && available_connections = @replication_connections[method_name]
        available_connections.sample
      else
        raise ArgumentError, "Replication connections could not be found for #{method_name}."
      end
    end

    # Builds replication connection classes and methods
    def set_replications_connections(options)
      [:masters,:slaves].each do |type|
        cons = (options[type].empty? ? connection.replications[type] : options[type])
        unless cons.empty?
          @replication_connections ||= {}
          cons.each do |to_use|
            @replication_connections[type] ||= []
            @replication_connections[type] << fetch_connection_class_name(to_use)
          end
        end
      end
      raise ArgumentError, "Connection class could not be found for #{self.name}." unless (replicated? && (@replication_connections[:masters] || @replication_connections[:slaves]))
      @replication_connections
    end

    def fetch_connection_class_name(to_use)
      conn_class_name = to_use
      conn_class_name = fetch_connection_class_name_from_yml_key(conn_class_name) if conn_class_name.to_s =~ /_/
      raise ArgumentError, "For #{self.name}, the class #{conn_class_name} could not be found." if conn_class_name.blank?
      conn_class_name
    end

    def fetch_connection_class_name_from_yml_key(yml_key)
      found = managed_connections[yml_key]
      raise ArgumentError, "For #{self.name}, a connection class for #{yml_key} could not be found." unless found
      found
    end
  end
end
ActiveRecord::Base.extend(ConnectionManager::Replication)
