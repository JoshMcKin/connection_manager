require 'active_support/core_ext/hash/indifferent_access'
module ConnectionManager
  module ConnectionHelpers       
    @@managed_connections = HashWithIndifferentAccess.new
    
    # Returns the database_name of the connection unless set otherwise
    def database_name
      @database_name = "#{connection.config[:database].to_s}" if @database_name.blank?
      @database_name
    end
    alias :schema_name :database_name
    
    # Sometimes we need to manually set the database name, like when the connection
    # has a database but our table is in a different database/schema but on the
    # same DMS.
    def database_name=database_name
      @database_name = database_name
    end
    alias :schema_name= :database_name=
    
    
    # Returns true if this is a readonly only a readonly model
    # If the connection.readonly? then the model that uses the connection 
    # must be readonly.
    def readonly?
      ((@readonly == true)||connection.readonly?)
    end
    
    # Allow setting of readonly at the model level
    def readonly=readonly
      @readonly = readonly
    end
    
    # A place to store managed connections
    def managed_connections
      @@managed_connections
    end
    
    def add_managed_connections(yml_key,value)
      @@managed_connections[yml_key] ||= []
      @@managed_connections[yml_key] << value unless @@managed_connections[yml_key].include?(value)
      @@managed_connections
    end
    
    def managed_connection_classes
      managed_connections.values.flatten
    end
    
    def yml_key
      @yml_key
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
    def use_database(database_name,opts={})
      @database_name = database_name
      opts[:table_name_prefix] ||= "#{database_name}."
      opts[:table_name] ||= self.table_name
      opts[:table_name] = opts[:table_name].to_s.split('.').last
      self.table_name_prefix = opts[:table_name_prefix]
      self.table_name = "#{opts[:table_name_prefix]}#{opts[:table_name]}" unless self.abstract_class?
    end
    alias :use_schema :use_database
   
    # Establishes and checks in a connection, normally for abstract classes AKA connection classes.
    # 
    # Options:
    # * :abstract_class - used the set #abstract_class, default is true
    # * :readonly - force all instances to readonly
    # * :class_name - name of connection class name, default is current class name
    # * :table_name_prefix - prefix to append to table name for cross database joins,
    #     default is the "#{self.database_name}."
    # EX:
    #   class MyConnection < ActiveRecord::Base
    #     establish_managed_connection :key_from_db_yml,{:readonly => true}
    #   end
    #
    def establish_managed_connection(yml_key,opts={})
      @yml_key = yml_key
      opts = {:class_name => self.name, 
        :abstract_class => true}.merge(opts)   
      establish_connection(yml_key)     
      self.abstract_class = opts[:abstract_class]
      set_to_readonly if (readonly? || opts[:readonly] || self.connection.readonly?)
      add_managed_connections(yml_key,opts[:class_name])
      use_database(self.database_name,opts) unless self.abstract_class
    end
          
    # Override ActiveRecord::Base instance method readonly? to force 
    # readonly connections.
    def set_to_readonly
      self.readonly = true
      define_method(:readonly?) do 
        true
      end  
    end
  end
end