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
        ActiveRecord::Base.configurations[name_from_yml]['database'].to_s
      end
    
      # Given an connection key name from the database.yml, returns the string 
      # equivelent of the class name for that entry.
      def connection_class_name(name_from_yml)
        name_from_yml = name_from_yml #clean up sqlite database names
        new_class_name = name_from_yml.gsub(Regexp.new("#{env}$"),'')
        new_class_name = database_name_from_yml(name_from_yml) if new_class_name.blank?
      
        #cleanup sqlite database names
        if new_class_name.gsub!(/(^db\/)|(\.sqlite3$)/,'')  
          new_class_name.gsub!(Regexp.new("(\\_#{env}$)"),'')
        end
      
        new_class_name = new_class_name.gsub(/\_/,' ').titleize.gsub(/ /,'')
        new_class_name << "Connection"
        new_class_name
      end 
     
   
    
      def add_replication_connection(name_from_yml,new_connection)    
        rep_name = "#{name_from_yml}".gsub(Regexp.new("(#{env}$)"),'')
        if rep_name.blank?
          db_name = database_name_from_yml(name_from_yml)
          if db_name.gsub!(/(\.sqlite3$)/,'')  
            db_name = db_name.split("/").last
            db_name.gsub!(Regexp.new("(\\_#{env}$)"),'')
          end  
          rep_name = db_name
        end
        rep_name.gsub!(/(\_)+(\d+)/,'')
        rep_name.gsub!(/\_$/,'')
        rep_name = rep_name.to_sym
        replication_connections[rep_name] ||= []
        replication_connections[rep_name] << new_connection
        replication_connections
      end
    
    
      def connections_for_replication(rep_collection_key)
        replication_connections[rep_collection_key.to_sym]
      end
    
      # Sets class instance attributes, then builds connection classes, while populating
      # available_connctions and replication_connection
      def initialize(options={})  
        options.each do |k,v|
          send("#{k.to_s}=",v)
        end     
        connection_keys.each do |connection|
          new_connection = connection_class_name(connection)     
          add_replication_connection(connection,new_connection)
          build_connection_class(new_connection,connection)       
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
