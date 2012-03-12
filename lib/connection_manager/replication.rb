require 'active_support/core_ext/hash/indifferent_access'
module ConnectionManager
  module Replication   
        
    # Contains all the replication connections available to this class where the
    # key is the method for calling the connection
    def replication_connections
      @replication_connections ||= HashWithIndifferentAccess.new
    end
    
    # Method to know when we are deaing with a model and when we are dealing
    # with a replication class
    def replication_class?
      false
    end
    
    # EX: 
    # class MyClass < ActiveRecord::Base
    #   replicated :my_readonly_db, "FooConnection", readonly => true, :method_name => 'east_region'
    # end
    #
    # Options:
    # * :method_name - name of class method to call to access replication, default to slave
    # * :readonly - forces all results to readonly
    # * :using - list of connections to use--- DEPRECIATED
    def replicated(*connections)   
      options = {:method_name => "slaves"}.merge(connections.extract_options!)
      connections = options[:using] if options[:using]
      build_replication_connections(connections,options)
    end
       
    # replication asscoaitions
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
    
    # builds a string that defines the replication associations for use with eval
    def build_replication_associations(class_name)
#      str = ""
#      defined_associations.each do |method,defs|
#        unless defs.blank?
#          defs.each do |association,options|
#            options = {} if options.blank?
#            unless options[:class_name].to_s.match("::#{class_name}")
#              str << "#{method.to_s} :#{association}, #{replication_association_options(method,association,class_name,options)};" 
#            end
#          end
#        end
#      end
#      str
    end 
    
    # Builds replication connection classes and methods
    def build_replication_connections(connections,options) 
      options[:method_name] ||= 'slaves'
      raise ArgumentError, "connections are required."if connections.blank?
      unless replication_class?        
        connection_methods = []
        connections.each do |to_use| 
          if to_use.to_s.match(/_/)       
            build_from_yml_key(to_use,connection_methods,options)
          else
            build_from_class_name(to_use,connection_methods,options)
          end
        end
        build_replication_method(connection_methods, options[:method_name])      
      end
    end
    
    # Runs methods to build replication connections. Replication connection class are
    # appended with 'Child'
    def build_replication_resources(class_name,method_name,connection_methods,options)
      child_class_name = "#{self.name}#{class_name}Child"
      connection_methods << method_name.to_sym     
      replication_connections[method_name] = build_replication_class(class_name,child_class_name,options)
      build_single_replication_method(method_name)            
    end
    
    def build_from_class_name(class_name,connection_methods,options)     
      if(managed_connection_classes.include?(class_name))
        method_name = class_name.underscore
        build_replication_resources(class_name,method_name,connection_methods,options)
      else
        raise ArgumentError, "A connection for #{class_name} could not be found."   
      end
    end

    def build_from_yml_key(yml_key,connection_methods,options)
      found = managed_connections[yml_key]
      if found     
        class_name = found.first
        method_name = class_name.underscore
        build_replication_resources(class_name,method_name,connection_methods,options)
      else
        raise ArgumentError, "A connection for #{yml_key} could not be found." 
      end
    end  
    
    # Creats a that inherets from the model. The default model_name 
    # class method is overriden to return the super's name, which ensures rails
    # helpers like link_to called on a replication stance generate a url for the
    # master database. If options include readonly, build_replication_class also 
    # overrides the rails "readonly?" method to ensure saves are prevented. 
    # replication class can be called directly for operaitons.
    # Usage: 
    #   UserSlave1ConnectionChild.where(:id => 1).first => returns results from slave_1 database
    #   UserSlave2ConnectionChild.where(:id => 2).first => returns results from slave_2 database
    #   UserShardConnectionChild.where(:id => 2).first => returns results from shard database
    def build_replication_class(class_name,child_class_name,options)    
      begin
        rep_class = class_eval(child_class_name)
      rescue NameError 
        klass = Class.new(self) do
          self.table_name = "#{table_name}"
          self.table_name_prefix = "#{database_name}." unless self.database_name.match(/\.sqlite3$/)
          class << self
            def model_name
              superclass.model_name
            end         
            def replication_class?
              true  
            end
          end
        end          
        rep_class = Object.const_set(child_class_name, klass)
        if options[:readonly] || class_name.constantize.readonly?     
          rep_class.class_eval do
            define_method(:readonly?) do 
              true
            end
          end       
        end      
        rep_class.class_eval <<-STR, __FILE__, __LINE__       
            class << self             
              def connection
                #{class_name}.connection
              end
            end
        STR
      end   
      rep_class.build_replication_associations(class_name)      
      rep_class
    end
     
    # Adds as class method to call a specific replication conneciton.
    # Usage:
    #   User.slave_1.where(:id => 2).first => returns results from slave_1 database
    #   User.slave_2.where(:id => 2).first => returns results from slave_2 database
    def build_single_replication_method(method_name)
      self.class.instance_eval do       
        define_method method_name.to_s do
          replication_connections[method_name]
        end
      end
    end
    
    # add a class method that shifts through available connections methods
    # on each call.
    # Usage:
    #   User.slave.where(:id => 2).first => can return results from slave_1 or slave_2 
    def build_replication_method(connection_methods,method_name='slaves')
      @replication_methods = connection_methods
      self.class.instance_eval do       
        define_method method_name do
          current = @replication_methods.shift
          @replication_methods << current
          send(current)
        end
      end
    end
    
    # After the replication class is defined we need to add replication_associations 
    # should the super class be redefined else where with other associations added,
    # think Rails engine...
    def after_association
#      replication_connections.values.each do |rep|
#        rep.constantize.class_eval(build_replication_associations(rep))
#      end
    end
  end
end