require 'thread'
require 'active_record/relation'
module ConnectionManager
  module ConnectionHandling
    @@managed_connections = ThreadSafe::Cache.new

    # Attempts to return the schema from table_name and table_name_prefix
    def schema_name
      return self.table_name.split('.')[0] if self.table_name && self.table_name =~ /\./
      return self.table_name_prefix.to_s.gsub(/\./,'') if self.table_name_prefix && self.table_name_prefix =~ /\./
      return self.connection.config[:database] if self.connection.mysql?
    end
    alias :database_name :schema_name

    # Set the unformatted schema name for the given model / connection class
    # EX: class User < ActiveRecord::Base
    #       self.schema_name = 'users_db'
    #     end
    #
    #     User.schema_name        # => 'users_db'
    #     User.table_name_prefix  # => 'users_db.'
    #     User.table_name         # => 'users_db.users'
    def schema_name=schema_name
      self.table_name_prefix = "#{schema_name}." if schema_name && !schema_name.blank?
      self.table_name = "#{self.table_name_prefix}#{self.table_name}" unless self.abstract_class?
    end
    alias :database_name= :schema_name=

    # A place to store managed connections
    def managed_connections
      @@managed_connections
    end

    def managed_connection_classes
      managed_connections.values.flatten
    end

    # Establishes and checks in a connection, normally for abstract classes AKA connection classes.
    #
    # Options:
    # * :abstract_class - used the set #abstract_class, default is true
    # * :schema_name - the unformatted schema name for connection, is inherited but child classes
    # * :table_name - the table name for the model, should not be used on abstract classes
    #
    # EX:
    #   class MyConnection < ActiveRecord::Base
    #     establish_managed_connection :key_from_db_yml,{:readonly => true}
    #   end
    #
    def establish_managed_connection(yml_key,opts={})
      opts = {:class_name => self.name,
              :abstract_class => true}.merge(opts)
      establish_connection(yml_key)
      self.abstract_class = opts[:abstract_class]
      self.table_name = opts[:table_name] if opts[:table_name]
      if (opts[:schema_name] || opts[:database_name])
        self.schema_name = (opts[:schema_name] || opts[:database_name])
      else
        self.schema_name = self.schema_name unless !self.connection.cross_schema_support?
      end
    end

    def self.included(base)
      base.alias_method_chain :establish_connection, :managed_connections
    end

    def self.extended(base)
      class << base
        self.alias_method_chain :establish_connection, :managed_connections
      end
    end

    def establish_connection_with_managed_connections(spec = nil)
      result = establish_connection_without_managed_connections(spec)
      if spec && (spec.is_a?(Symbol) || spec.is_a?(String))
        self.managed_connections[spec.to_sym] = self.name
      elsif spec.nil? && ConnectionManager.env
        self.managed_connections[ConnectionManager.env.to_sym] = self.name
      else
        self.managed_connections[self.name] = self.name
      end
      result
    end
  end
end
ActiveRecord::ConnectionHandling.send(:include, ConnectionManager::ConnectionHandling)

