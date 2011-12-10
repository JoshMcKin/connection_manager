module ConnectionManager
  module ReplicationBuilder
    
    def database_name
      "#{connection.instance_variable_get(:@config)[:database].to_s}"
    end
    
    def replication_association_options(method,association,class_name,options={})
      new_options = {}.merge(options)
      if new_options[:class_name].blank?
        new_options[:class_name] = "#{association.to_s.singularize.classify}::#{class_name}"
      else
        new_options[:class_name] = "#{new_options[:class_name]}::#{class_name}"
      end
      
      if [:has_one,:has_many].include?(method) && new_options[:foreign_key].blank? 
        new_options[:foreign_key] = "#{table_name.singularize}_id"
      end     
      new_options
    end
    
    def build_replication_associations(class_name)
      str = ""
      defined_associations.each do |method,defs|
        unless defs.blank?
          defs.each do |association,options|
            options = {} if options.blank?
            unless options[:no_readonly] || options[:class_name].to_s.match("::#{class_name}")
              str << "#{method.to_s} :#{association}, #{replication_association_options(method,association,class_name,options)};" 
            end
          end
        end
      end
      str
    end
    
    def replication_connection_classes(options)
      if options[:using] && options[:using].is_a?(Array)
        connection_classes = options[:using].collect{|c| Connections.connection_class_name(c)}
      else  
        rep_name = "#{options[:name].to_s}_#{Connections.clean_sqlite_db_name(database_name)}"
        connection_classes = Connections.connections_for_replication(rep_name) 
      end
      connection_classes
    end

    
    # Adds subclass with the class name of the type provided in the options, which 
    # defaults to 'slave' if blank, that uses the connection from a connection class.
    # If :database option is blank?, replicated will assume the database.yml has
    # slave connections defined as: slave_database_name_test or slave_1_database_name_test, 
    # where slave_1 is the replication instance, 'database_name' is the actual 
    # name of the database and '_test' is the Rails environment
    def replicated(*settings)   
      options = {:name => "slave", :readonly => true}.merge(settings.extract_options!)   
      connection_classes = replication_connection_classes(options)  
      if connection_classes.blank?
        raise ArgumentError, " a replication connection was not found. Check your database.yml."
      else   
        connection_methods = []
        connection_classes.each do |c|
          under_scored = c.underscore
          method_name = under_scored.split("_")[0]
          method_name = method_name.insert(method_name.index(/\d/),"_")
          class_name = method_name.classify
          connection_methods << method_name.to_sym
          build_replication_class(class_name,c,options)
          build_single_replication_method(method_name,class_name)
        end
      end
      build_full_replication_method(options,connection_methods)   
  
    end
    
    # Creats a subclass that inherets from the model. The default model_name 
    # class method is overriden to return the super's name, which ensures rails
    # helpers like link_to called on a replication stance generate a url for the
    # master database. If options include readonly, build_replication_class also 
    # overrides the rails "readonly?" method to ensure saves are prevented. 
    # Replication class can be called directly for operaitons.
    # Usage: 
    #   User::Slave1.where(:id => 1).first => returns results from slave_1 database
    #   User::Slave2.where(:id => 2).first => returns results from slave_1 database
    def build_replication_class(class_name,connection_name,options)
      class_eval <<-STR, __FILE__, __LINE__
      class #{class_name} < self
        #{build_replication_associations(class_name)}
        class << self
          def connection
            Connections::#{connection_name}.connection
          end

          def model_name
            ActiveModel::Name.new(#{name})
          end
        end
        #{'def readonly?; true; end;' if (options[:name] == "readonly" || options[:readonly])}       
      end       
      STR
    end
    
    # Adds as class method to call a specific replication conneciton.
    # Usage:
    #   User.slave_1.where(:id => 2).first => returns results from slave_1 database
    #   User.slave_2.where(:id => 2).first => returns results from slave_2 database
    def build_single_replication_method(method_name,class_name)
      class_eval <<-STR, __FILE__, __LINE__
        class << self
          def #{method_name}
            self::#{class_name}
          end      
        end 
      STR
    end
    
    # add a class method that shifts through available connections methods
    # on each call.
    # Usage:
    #   User.slave.where(:id => 2).first => can return results from slave_1 or slave_2 
    def build_full_replication_method(options,connection_methods)
      class_eval <<-STR, __FILE__, __LINE__
      @connection_methods = #{connection_methods}
      class << self
        def #{options[:name].to_s}
          current = @connection_methods.shift
          @connection_methods << current
          send(current)
        end
        def connection_methods
          @connection_methods
        end
      end     
      STR
    end
  end
end
ActiveRecord::Base.extend(ConnectionManager::ReplicationBuilder)
