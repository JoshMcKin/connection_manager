require 'active_support/core_ext/hash/indifferent_access'
module ConnectionManager
  module ConnectionBuilder         
      
    # Get the current environment if defined
    # Check for Rails, check for RACK_ENV, default to 'development'
    def ar_env
      return Rails.env if defined?(Rails)
      return RACK_ENV if defined?(RACK_ENV)
      return ENV["AR_ENV"] if ENV["AR_ENV"]
      "development"
    end
    
    # Grab only those connections that correspond to the current env. If env
    # is blank it grabs all the connection keys
    # 
    # If you current environment valid database keys can be:
    # * development
    # * other_database_development
    # * slave_database_development  
    def configuration_keys
      ActiveRecord::Base.configurations.keys.select{|n| n.match(ar_env_regex)}
    end
      
    def database_yml_attributes(name_from_yml)
      found = ActiveRecord::Base.configurations[name_from_yml]
      ActiveRecord::Base.configurations[name_from_yml].symbolize_keys if found
    end
        
    # Returns currently loaded configurations where :build_connection is true
    def database_keys_for_auto_build
      ab_configs = []
      configuration_keys.each do |key|    
        ab_configs << key if (database_yml_attributes(key)[:build_connection_class] == true)
      end
      ab_configs
    end
    
    # Builds connection classes using the database keys provided; expects an array.
    def build_connection_classes(database_keys_to_use=database_keys_for_auto_build)      
      database_keys_to_use.each do |key|
        build_connection_class(connection_class_name(key),key) 
      end
    end 
    
    # Build connection classes base on the supplied class name and connection 
    # key from database.yml
    def build_connection_class(class_name,connection_key)
      begin
        class_name.constantize
      rescue NameError 
        klass = Class.new(ActiveRecord::Base)
        new_connection_class = Object.const_set(class_name, klass)  
        new_connection_class.establish_managed_connection(connection_key)
        new_connection_class.use_database(new_connection_class.current_database_name)
      end
    end
    
    private
    def ar_env_regex
      return @ar_env_regex if @ar_env_regex
      s = "#{ar_env}$"
      @ar_env_regex = Regexp.new("(#{s})")
    end
      
    # Creates a string to be used for the class name. Removes the current env.
    def clean_yml_key(name)
      new_name = "#{name}".gsub(ar_env_regex,'')      
      new_name = "Base"if new_name.blank?
      new_name.gsub(/\_$/,'')
    end
      
    # Given an connection key name from the database.yml, returns the string 
    # equivalent of the class name for that entry.
    def connection_class_name(name_from_yml)
      new_class_name = clean_yml_key(name_from_yml)
      new_class_name = new_class_name.gsub(/\_/,' ').titleize.gsub(/ /,'')
      new_class_name << "Connection"
      new_class_name
    end
  end
end