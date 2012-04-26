require 'active_support/core_ext/hash/indifferent_access'
require 'thread'
module ConnectionManager
  module Replication 
    @replication_methods = []
    @replication_method_name = ""
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
    
    def replicated?
      @replicated == true
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
      @replicated = true
      options = {:method_name => "slaves"}.merge(connections.extract_options!)
      if options[:using]
        connections = options[:using] 
        warn "[DEPRECATION] :using option is deprecated.  Please list replication connections instead. EX: replicated :slave_connection,'OtherSlaveConnectionChild'."
      end
      connections = connection.replication_keys if connections.blank?
      build_replication_connections(connections,options)
    end
       
    # replication associations
    def replication_association_options(method,association,method_name='slaves',options={})
      klass_method_name = method_name.classify
      klass_method_name = "Slave" if klass_method_name == "Slafe"
      new_options = {}.merge(options)
      new_options[:readonly] = true if readonly?
      new_options[:class_name] = (new_options[:class_name].blank? ? "#{association.to_s.singularize.classify}::#{klass_method_name}" : "#{new_options[:class_name]}::#{klass_method_name}")
      new_options[:foreign_key] = "#{table_name.split('.').last.singularize}_id" if ([:has_one,:has_many,:has_and_belongs_to].include?(method) && new_options[:foreign_key].blank?) 
      new_options
    end
    
    # builds a string that defines the replication associations for use with eval
    def build_replication_associations(defined_associations,method_name)
      str = ""
      defined_associations.each do |method,defs|
        unless defs.blank?
          defs.each do |association,options|
            options = {} if options.blank?         
            unless options[:class_name].to_s.match(/Child$/) 
              str << "#{method.to_s} :#{association}, #{replication_association_options(method,association,method_name,options)};" 
            end
          end
        end
      end
      class_eval(str)
    end 
    
    # Builds replication connection classes and methods
    def build_replication_connections(connections,options={}) 
      options[:name] ||= 'slaves'
      raise ArgumentError, "connections are required."if connections.blank?
      if replication_class?
        return false
      else
        connection_methods = []
        connections.each do |to_use| 
          if to_use.to_s.match(/_/)       
            build_from_yml_key(to_use,connection_methods,options)
          else
            build_from_class_name(to_use,connection_methods,options)
          end
        end
        build_replication_method(connection_methods, options[:name])      
      end
      true
    end
    
    # Runs methods to build replication connections. Replication connection class are
    # appended with 'Child'
    def build_replication_resources(connection_class_name,method_name,connection_methods,options)
      child_class_name = "#{self.name}#{connection_class_name}Child"
      connection_methods << method_name.to_sym     
      replication_connections[method_name] = build_replication_class(connection_class_name,child_class_name,options)
      build_single_replication_method(method_name)    
      add_replication_class(options[:name])
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
    
    # Creats a class that inherets from the model. The default model_name 
    # class method is overriden to return the super's name, which ensures rails
    # helpers like link_to called on a replication stance generate a url for the
    # master database. If options include readonly, build_replication_class also 
    # overrides the rails "readonly?" method to ensure saves are prevented. 
    # replication class can be called directly for operaitons.
    # Usage: 
    #   UserSlave1ConnectionChild.where(:id => 1).first => returns results from slave_1 database
    #   UserSlave2ConnectionChild.where(:id => 2).first => returns results from slave_2 database
    #   UserShardConnectionChild.where(:id => 2).first => returns results from shard database
    def build_replication_class(connection_class_name,child_class_name,options)
      begin
        rep_klass = class_eval(child_class_name)
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
        klass.class_eval <<-STR, __FILE__, __LINE__       
           def self.connection
             '#{connection_class_name}'.constantize.connection
           end
           
           @replication_method_name = '#{options[:name]}'
        STR
        
        if options[:readonly] || connection_class_name.constantize.readonly?     
          klass.class_eval do
            define_method(:readonly?) do 
              true
            end
          end       
        end
        klass.build_replication_associations(defined_associations,options[:name])
        rep_klass = Object.const_set(child_class_name, klass)    
      end   
      rep_klass
    end
      
    # In order to ensure a replication 
    def add_replication_class(method_name)
      klass_method_name = method_name.classify
      klass_method_name = "Slave" if klass_method_name == "Slafe"
      class_eval <<-STR, __FILE__, __LINE__       
         class #{klass_method_name} < self
            def self.constantize
              super.#{method_name}
            end
         end
      STR
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
    
    def _replication_mutex
      @replication_mutex ||= (connection.using_em_adapter? ? EM::Synchrony::Thread::Mutex.new : Mutex.new)
    end
    
    # Make sure multiple threads do not through off our shifting
    def fetch_replication_method
      _replication_mutex.synchronize {
        current = @replication_methods.shift
        @replication_methods << current
        send(current)
      }
    end

    # add a class method that shifts through available connections methods
    # on each call.
    # Usage:
    #   User.slave.where(:id => 2).first => can return results from slave_1 or slave_2 
    def build_replication_method(connection_methods,method_name='slaves')
      @replication_methods = connection_methods       
      self.class.instance_eval do            
        define_method method_name do
          fetch_replication_method
        end        
      end
    end
    
    # After the replication class is defined we need to add replication_associations 
    # should the super class be redefined else where with other associations added,
    # think Rails engine...
    def after_association
      replication_connections.values.each do |rep|
        rep.constantize.build_replication_associations(defined_associations,@replication_method_name)
      end
    end
  end
end