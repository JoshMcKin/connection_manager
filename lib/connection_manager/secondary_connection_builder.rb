module ConnectionManager
  module SecondaryConnectionBuilder
   
    def database_name
      "#{connection.instance_variable_get(:@config)[:database].to_s}"
    end
    
    def secondary_association_options(method,association,class_name,options={})
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
    
    def build_secondary_associations(class_name)
      str = ""
      defined_associations.each do |method,defs|
        unless defs.blank?
          defs.each do |association,options|
            options = {} if options.blank?
            unless options[:no_readonly] || options[:class_name].to_s.match("::#{class_name}")
              str << "#{method.to_s} :#{association}, #{secondary_association_options(method,association,class_name,options)};" 
            end
          end
        end
      end
      str
    end
    
    def secondary_connection_classes(options)
      if options[:using] && options[:using].is_a?(Array)
        connection_classes = options[:using].collect{|c| Connections.connection_class_name(c)}
      else  
        rep_name = "#{options[:name].to_s}_#{Connections.clean_sqlite_db_name(database_name)}"
        connection_classes = Connections.available_secondary_connections(rep_name) 
      end
      connection_classes
    end
    
    def replicated(*settings)   
      options = {:name => "slave", :readonly => true, :replication => true}.merge(settings.extract_options!)
      build_secondary_connections(options)
    end
    
    def shard(*settings)   
      options = {:name => "shard", :readonly => false, :shards => true}.merge(settings.extract_options!) 
      build_secondary_connections(options)
    end
    
    def child_connection_class?
      false
    end    
    # Adds subclass with the class name of the type provided in the options, which 
    # defaults to 'slave' if blank, that uses the connection from a connection class.
    # If :database option is blank?, replicated will assume the database.yml has
    # slave connections defined as: slave_database_name_test or slave_1_database_name_test, 
    # where slave_1 is the secondary instance, 'database_name' is the actual 
    # name of the database and '_test' is the Rails environment
    def build_secondary_connections(options={})   
      unless name.match(/\:\:/)
        connection_classes = secondary_connection_classes(options)  
        sub_classes = []
        if connection_classes.blank?
          raise ArgumentError, " a secondary connection was not found. Check your database.yml."
        else   
          connection_methods = []
          connection_classes.each do |c|
            under_scored = c.underscore
            method_name = under_scored.split("_")[0]
            method_name = method_name.insert(method_name.index(/\d/),"_")
            class_name = method_name.classify
            connection_methods << method_name.to_sym
#            set_table_name_for_joins
            build_secondary_class(class_name,c,options)
            build_single_secondary_method(method_name,class_name)            
            sub_classes << "#{self.name}::#{class_name}".constantize if options[:shards]
          end
        end
        build_slaves_method(connection_methods)  if options[:replication]
        build_shards_method(sub_classes)  if options[:shards]
      end
    end
    
    # Creats a subclass that inherets from the model. The default model_name 
    # class method is overriden to return the super's name, which ensures rails
    # helpers like link_to called on a secondary stance generate a url for the
    # master database. If options include readonly, build_secondary_class also 
    # overrides the rails "readonly?" method to ensure saves are prevented. 
    # secondary class can be called directly for operaitons.
    # Usage: 
    #   User::Slave1.where(:id => 1).first => returns results from slave_1 database
    #   User::Slave2.where(:id => 2).first => returns results from slave_2 database
    #   User::Shard1.where(:id => 2).first => returns results from slave_1 database
    def build_secondary_class(class_name,connection_name,options)
      klass = Class.new(self) do
        class << self
          def model_name
            ActiveModel::Name.new(superclass)
          end         
          def child_connection_class?
            true  
          end
        end
        
        if (options[:name] == "readonly" || options[:readonly])
          def readonly?
            true
          end
        end
      end 
 
      sub_class = const_set(class_name, klass)
      sub_class.build_secondary_associations(class_name)      
      sub_class.class_eval <<-STR, __FILE__, __LINE__
        class << self
          def connection
            Connections::#{connection_name}.connection
          end
        end
      STR
      connection_sub_classes << sub_class
      sub_class
    end
    
    def connection_sub_classes
      @connection_sub_classes ||= []
    end
    
    def set_table_name_for_joins
      self.table_name_prefix = "#{database_name}." unless database_name.match(/\.sqlite3$/)
    end
    
    # Adds as class method to call a specific secondary conneciton.
    # Usage:
    #   User.slave_1.where(:id => 2).first => returns results from slave_1 database
    #   User.slave_2.where(:id => 2).first => returns results from slave_2 database
    def build_single_secondary_method(method_name,class_name)
      self.class.instance_eval do       
        define_method method_name.to_s do
          "#{name}::#{class_name}".constantize
        end
      end
    end
    
    # add a class method that shifts through available connections methods
    # on each call.
    # Usage:
    #   User.slave.where(:id => 2).first => can return results from slave_1 or slave_2 
    def build_slaves_method(connection_methods)
      @connection_methods = connection_methods
      self.class.instance_eval do       
        define_method 'slaves' do
          current = @connection_methods.shift
          @connection_methods << current
          send(current)
        end
        alias_method :slave, :slaves
      end
    end
    
    # add a class method that shifts through available connections methods
    # on each call.
    # Usage:
    #   User.shards.where(:id => 2).first => can return results from slave_1 or slave_2 
    def build_shards_method(connection_classes)    
      self.class.instance_eval do
        define_method 'shards' do
          ConnectionManager::MethodRecorder.new(connection_classes)
        end
      end
    end
  end
end