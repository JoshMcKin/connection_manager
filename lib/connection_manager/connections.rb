module ConnectionManager
  class Connections
    class << self
      @connection_keys
      @all
      @replication_connections
      @env 
    
      def env
        @env ||= fetch_env
        @env
      end
    
      def env=env
        @env = env
      end
    
      # Get the current Rails environment if defined
      # TODO add sinatra
      def fetch_env
        Rails.env if defined?(Rails)
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
      def replication_connections
        @replication_connections ||= {}
      end
    
      # Returns the database value given a connection key from the database.yml
      def database_name_from_yml(name_from_yml)
        ActiveRecord::Base.configurations[name_from_yml]['database']

      end
    
      def clean_sqlite_db_name(name)
        new_name = "#{name}".gsub(/(\.sqlite3$)/,'')  
        new_name = new_name.split("/").last 
        new_name.gsub!(Regexp.new("(\_#{env}$)"),'')
        new_name
      end
      
      def clean_bd_name(name)
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
        new_class_name = clean_bd_name(name_from_yml)  
        new_class_name = new_class_name.gsub(/\_/,' ').titleize.gsub(/ /,'')
        new_class_name << "Connection"
        new_class_name
      end 
     
      def replication_key(name_from_yml)
        rep_name = clean_bd_name(name_from_yml)
        rep_name.gsub!(/(\_)+(\d+)/,'')
        rep_name.to_sym   
      end
    
      def add_replication_connection(name_from_yml,new_connection)    
        key = replication_key(name_from_yml)
        replication_connections[key] ||= []
        replication_connections[key] << new_connection
        replication_connections
      end
    
      def connections_for_replication(rep_collection_key)
        replication_connections[(rep_collection_key.gsub(Regexp.new("(\_#{env}$)"),'')).to_sym]
      end
    
      # Sets class instance attributes, then builds connection classes, while populating
      # available_connctions and replication_connection
      def initialize(options={})  
        options.each do |k,v|
          send("#{k.to_s}=",v)
        end     
        connection_keys.each do |connection|
          #puts ActiveRecord::Base.configurations["test"]
          new_connection = connection_class_name(connection)  
          #puts ActiveRecord::Base.configurations["test"]
          add_replication_connection(connection,new_connection)
          #puts ActiveRecord::Base.configurations["test"]
          build_connection_class(new_connection,connection) 
          #puts ActiveRecord::Base.configurations["test"]
        end
        all
      end 
    
      # Addes a conneciton subclass to AvailableConnections using the supplied
      # class name and connection key from database.yml
      def build_connection_class(class_name,connection_key)
        class_eval <<-STR, __FILE__, __LINE__
        class #{class_name} < ActiveRecord::Base
          self.abstract_class = true
          establish_connection("#{connection_key}")
        end
        STR
        all << class_name
      end
    end
  end
end
