module ConnectionManager
  class Connections
    class << self
      @@config = {:auto_replicate => false, :env => 'development'}     
      @connection_keys
      
      # Hold config options
      def config(options={})
        @@config = (@@config.merge!(options)) unless options.empty?
        @@config
      end
      
      # Easy access to env
      def env
        @@config[:env]
      end
    
      def env=env
        @@config[:env] = env
        @@config[:env]
      end
      
      # Easy access to auto_replicate
      def auto_replicate
        @@config[:auto_replicate]
      end
      
      def auto_replicate=auto_replicate
        @@config[:auto_replicate] = auto_replicate
        @@config[:auto_replicate]
      end  
            
      def auto_replicate?
        (@@config[:auto_replicate] == true)
      end
      
      def env_regex(with_underscore=true)
        s = "#{env}$"
        s.insert(0,"\_") if with_underscore
        Regexp.new("(#{s})")
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
          select{|n| n.match(env_regex(false))}
      end
    
      def exists_in_database_yml?(name_from_yml)
        !ActiveRecord::Base.configurations[name_from_yml].blank?
      end
      
      def database_yml_attributes(name_from_yml)
        ActiveRecord::Base.configurations[name_from_yml].symbolize_keys if exists_in_database_yml?(name_from_yml)
      end
      
      # Returns the database value given a connection key from the database.yml
      def database_name_from_yml(name_from_yml)
        clean_db_name(database_yml_attributes(name_from_yml)[:database]) if exists_in_database_yml?(name_from_yml)
      end
      
      def clean_sqlite_db_name(name,remove_env=true)
        new_name = "#{name}".gsub(/(\.sqlite3$)/,'') 
        new_name = new_name.split("/").last 
        new_name.gsub!(env_regex,'') if remove_env
        new_name
      end
      
      def clean_db_name(name)
        new_name = "#{name}".gsub(env_regex(false),'')      
        new_name = "#{database_name_from_yml(name)}"if new_name.blank?
        new_name = clean_sqlite_db_name(new_name)
        new_name.gsub(/\_$/,'')
      end
      
      # Creates a string to be used for the class name. Removes the current env.
      def clean_yml_key(name)
        new_name = "#{name}".gsub(env_regex(false),'')      
        new_name = "Base"if new_name.blank?
        new_name.gsub(/\_$/,'')
      end
      
      # Given an connection key name from the database.yml, returns the string 
      # equivelent of the class name for that entry.
      def connection_class_name(name_from_yml)
        new_class_name = clean_yml_key(name_from_yml)
        new_class_name = new_class_name.gsub(/\_/,' ').titleize.gsub(/ /,'')
        new_class_name << "Connection"
        new_class_name
      end 
      
      def available_secondary_connections(rep_collection_key)
        secondary_connections[(rep_collection_key.gsub(env_regex,'')).to_sym]
      end
    
      # Sets class instance attributes, then builds connection classes, while populating
      # available_connctions and replication_connection
      def build_connection_classes(options={})  
        options.each do |k,v|
          send("#{k.to_s}=",v)
        end     
        connection_keys.each do |connection|
          build_connection_class(connection_class_name(connection),connection) 
        end
      end 
    
      # Addes a conneciton subclass to Connections using the supplied
      # class name and connection key from database.yml
      def build_connection_class(class_name,connection_key)
        begin
          class_name.constantize
        rescue NameError       
          klass = Class.new(ActiveRecord::Base) do         
            self.establish_managed_connection(connection_key, {:class_name => class_name})
          end
          new_connection_class = Object.const_set(class_name, klass)      
          (const_set class_name, new_connection_class)
        end
      end
      
      
#      require 'active_record/schema_dumper'
#      filename = ENV['SCHEMA'] || "#{Rails.root}/db/schema.rb"
#      File.open(filename, "w:utf-8") do |file|
#        ActiveRecord::Base.establish_connection(Rails.env)
#        ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
#      end
    end
  end
end