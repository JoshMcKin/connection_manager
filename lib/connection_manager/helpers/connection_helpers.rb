require 'active_support/core_ext/hash/indifferent_access'
module ConnectionManager
  module ConnectionHelpers       
    @@managed_connections = HashWithIndifferentAccess.new
    
    def database_name
      "#{connection.database_name.to_s}"
    end
    
    # Returns whether or not a model is readonly only at the class level
    # If the connection.readonly? then the model that uses the connection 
    # must be readonly.
    def readonly?
      ((@readonly == true)||(connection.readonly?))
    end
    
    # Allow setting of readonly at the model level
    def readonly=readonly
      @readonly = readonly
    end
    
    # A place to store managed connections
    def managed_connections
      @@managed_connections
    end
    
    def managed_connection_classes
      managed_connections.values.flatten
    end
    
    def yml_key
      @yml_key
    end
   
    # Establishes and checks in a connection for abstract classes.
    # EX:
    #   class MyConnection < ActiveRecord::Base
    #     establish_managed_connection(:key_from_db_yml,{:readonly => true})
    #   end
    #
    def establish_managed_connection(yml_key,opts={})
      opts[:class_name] = self.name if opts[:class_name].blank?
      @yml_key = yml_key
      establish_connection(yml_key) 
      self.abstract_class = true
      set_to_readonly if readonly? || opts[:readonly] 
      managed_connections[yml_key] ||= []
      managed_connections[yml_key] << opts[:class_name] unless self.managed_connections[yml_key].include?(opts[:class_name])
      self.table_name_prefix = "#{self.database_name}." unless self.database_name.match(/\.sqlite3$/)
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