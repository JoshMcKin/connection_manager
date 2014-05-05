require 'thread'
require 'active_record/relation'
module ConnectionManager
  module ConnectionHandling
    @@managed_connections = ThreadSafe::Cache.new

    # Attempts to return the schema from table_name and table_name_prefix
    def schema_name
      return self.table_name.split('.')[0] if self.table_name && self.table_name.match(/\./)
      self.table_name_prefix.to_s.gsub(/\./,'') if self.table_name_prefix && self.table_name_prefix.match(/\./)
    end

    # A place to store managed connections
    def managed_connections
      @@managed_connections
    end

    def managed_connection_classes
      managed_connections.values.flatten
    end

    # Tell Active Record to use a different database/schema on this model.
    # You may call #use_database when your schemas reside on the same database server
    # and you do not want to create extra connection class and database.yml entries.
    #
    # Options:
    # * :table_name_prefix - the prefix required for making cross database/schema
    # joins for you database management system. By default table_name_prefix is the
    # database/schema name followed by a period EX: "my_database."
    # * :table_name - the table name for the model if it does not match ActiveRecord
    # naming conventions
    #
    # EX: class LegacyUser < ActiveRecord::Base
    #       use_database('DBUser', :table_name => 'UserData')
    #     end
    #
    #     LegacyUser.limit(1).to_sql => "SELECT * FROM `BDUser`.`UserData` LIMIT 1
    #
    def use_database(database_name=nil,opts={})
      # self.current_database_name = database_name if database_name
      opts[:table_name_prefix] = "#{database_name}." if opts[:table_name_prefix].blank?
      unless self.abstract_class? || self.name == "ActiveRecord::Base"
        opts[:table_name] = self.table_name if opts[:table_name].blank?
        opts[:table_name].gsub!(self.table_name_prefix,'') unless self.table_name_prefix.blank?
        self.table_name = "#{opts[:table_name_prefix]}#{opts[:table_name]}"
      end
      self.table_name_prefix = opts[:table_name_prefix] unless opts[:table_name_prefix].blank?
    end
    alias :use_schema :use_database

    # Establishes and checks in a connection, normally for abstract classes AKA connection classes.
    #
    # Options:
    # * :abstract_class - used the set #abstract_class, default is true
    # * :class_name - name of connection class name, default is current class name
    # * :table_name_prefix - prefix to append to table name for cross database joins,
    #     default is the "#{self.database_name}."
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
      use_database(self.schema_name,opts)
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
if ActiveRecord::VERSION::MAJOR == 4
  ActiveRecord::ConnectionHandling.send(:include, ConnectionManager::ConnectionHandling)
else
  require 'active_record/base'
  ActiveRecord::Base.extend(ConnectionManager::ConnectionHandling)
end
