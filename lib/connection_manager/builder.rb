module ConnectionManager
  class Builder
    class << self
      # Grab only those configurations that correspond to the current env (If env
      # is blank it grabs all the connection keys) and where :build_connection_class is true
      def database_keys_for_auto_build
        ActiveRecord::Base.configurations.select{ |k,v| v[:build_connection_class] && k.match(env_regex)}.keys
      end

      # Builds connection classes using the database keys provided; expects an array.
      def build_connection_classes(database_keys_to_use=database_keys_for_auto_build)
        database_keys_to_use.each do |key|
          build_connection_class(connection_class_name(key),key.to_sym)
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
          new_connection_class.abstract_class = true
          new_connection_class.establish_connection(connection_key.to_sym)
          ConnectionManager.logger.info "Connection::Manager built: #{class_name} for #{connection_key}" if ConnectionManager.logger
          new_connection_class
        end
      end

      def env_regex
        return @env_regex if @env_regex
        s = "#{ConnectionManager.env}$"
        @env_regex = Regexp.new("(#{s})")
      end

      private
      # Creates a string to be used for the class name. Removes the current env.
      def clean_yml_key(name)
        new_name = "#{name}".gsub(env_regex,'')
        new_name = "Base" if new_name.blank?
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
end