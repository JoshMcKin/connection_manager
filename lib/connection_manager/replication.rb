module ConnectionManager
  module Replication
    attr_accessor :replication_connections
    # Replication methods (replication_method_name, which is the option[:name] for the
    # #replication method) and all their associated connections. The key is the
    # replication_method_name and the value is an array of all the replication_classes
    # the replication_method has access to.
    #
    # EX: replication_methods[:slaves] => ['Slave1Connection',Slave2Connection]
    def replication_connections
      @replication_connections ||= {:slaves => [], :masters => []}
    end


    # Is this class replicated
    def replicated?
      (@replication_connections && (!replication_connections[:slaves].empty? || !replication_connections[:masters].empty?))
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
      options = {:slaves => [], :masters => [], :type => :slaves}.merge(connections.extract_options!.symbolize_keys)
      options[options[:type]] = connections unless connections.empty?
      set_replications_connections(options)
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
      set_replications_connections(self.replication_connections) unless self.replicated?
      available_connections = self.replication_connections[method_name] || []
      raise ArgumentError, "No connections found for #{method_name}." if available_connections.blank?
      available_connections.sample
    end

    # Builds replication connection classes and methods
    def set_replications_connections(options)
      [:masters,:slaves].each do |type|
        cons = (options[type].empty? ? connection.replications[type] : options[type])
        unless cons.empty?
          self.replication_connections[type] = []
          cons.each do |to_use|
            self.replication_connections[type] << fetch_connection_class_name(to_use)
          end
        end
      end
      raise ArgumentError, "Connections could not be found for #{self.name}." if self.replication_connections[:masters].empty? && self.replication_connections[:slaves].empty?
      self.replication_connections
    end

    def fetch_connection_class_name(to_use)
      connection_class_name = to_use
      connection_class_name = fetch_connection_class_name_from_yml_key(connection_class_name) if connection_class_name.to_s.match(/_/)
      raise ArgumentError, "For #{self.name}, the class #{connection_class_name} could not be found." if connection_class_name.blank?
      connection_class_name
    end

    def fetch_connection_class_name_from_yml_key(yml_key)
      found = managed_connections[yml_key]
      raise ArgumentError, "For #{self.name}, a connection class for #{yml_key} could not be found." unless found
      found
    end
  end
end
ActiveRecord::Base.extend(ConnectionManager::Replication)
