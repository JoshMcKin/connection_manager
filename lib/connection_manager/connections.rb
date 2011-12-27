module ConnectionManager
  class Connections
    class << self
      @connection_keys
      @all
      @secondary_connections
      @env 
    
      def env
        @env ||= fetch_env
        @env
      end
    
      def env=env
        @env = env
      end
    
      # Get the current environment if defined
      # Check for Rails, check for RACK_ENV, default to 'development'
      def fetch_env
        return Rails.env if defined?(Rails)
        return RACK_ENV if defined?(RACK_ENV)
        "development"
      end
    
      # Grab only thoses connections that correspond to the current env. If env
      # is blank it grabs all the connection keys
      def connection_keys
        @connection_keys ||= ActiveRecord::Base.configurations.keys.
          select{|n| n.match(Regexp.new("(#{env}$)"))}
      end
    
      # Contains all the connection classes built
      def all
        @all ||= []
      end
    
      # Holds connections
      def secondary_connections
        @secondary_connections ||= {}
      end
    
      # Returns the database value given a connection key from the database.yml
      def database_name_from_yml(name_from_yml)
        clean_db_name(ActiveRecord::Base.configurations[name_from_yml]['database'])
      end
      
      def clean_sqlite_db_name(name,remove_env=true)
        new_name = "#{name}".gsub(/(\.sqlite3$)/,'')  
        new_name = new_name.split("/").last 
        new_name.gsub!(Regexp.new("(\_#{env}$)"),'') if remove_env
        new_name
      end
      
      def clean_db_name(name)
        new_name = "#{name}".gsub(Regexp.new("#{env}$"),'')
        if new_name.blank?
          new_name = "#{database_name_from_yml(name)}"
        end  
        new_name = clean_sqlite_db_name(new_name)
        new_name.gsub(/\_$/,'')
      end
      
      # Given an connection key name from the database.yml, returns the string 
      # equivelent of the class name for that entry.
      def connection_class_name(name_from_yml)
        new_class_name = clean_db_name(name_from_yml)  
        new_class_name = new_class_name.gsub(/\_/,' ').titleize.gsub(/ /,'')
        new_class_name << "Connection"
        new_class_name
      end 
     
      def secondary_key(name_from_yml)
        rep_name = clean_db_name(name_from_yml)
        rep_name.gsub!(/(\_)+(\d+)/,'')
        rep_name.to_sym   
      end
    
      def add_secondary_connection(name_from_yml,new_connection)    
        key = secondary_key(name_from_yml)
        secondary_connections[key] ||= []
        secondary_connections[key] << new_connection
        secondary_connections
      end
    
      def available_secondary_connections(rep_collection_key)
        secondary_connections[(rep_collection_key.gsub(Regexp.new("(\_#{env}$)"),'')).to_sym]
      end
    
      # Sets class instance attributes, then builds connection classes, while populating
      # available_connctions and replication_connection
      def initialize(options={})  
        options.each do |k,v|
          send("#{k.to_s}=",v)
        end     
        connection_keys.each do |connection|
          new_connection = connection_class_name(connection)  
          add_secondary_connection(connection,new_connection)
          build_connection_class(new_connection,connection) 
        end
        all
      end 
    
      # Addes a conneciton subclass to Connections using the supplied
      # class name and connection key from database.yml
      def build_connection_class(class_name,connection_key)
        klass = Class.new(ActiveRecord::Base) do         
          self.abstract_class = true
        end
        new_connection_class = Object.const_set(class_name, klass)
        new_connection_class.establish_connection(connection_key)       

        (const_set class_name, new_connection_class)
        all << class_name
      end
    end
  end
end
