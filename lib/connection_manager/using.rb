module ConnectionManager
  module Using
    module ClassMethods
      
      def using(connection_class_name)
        d = fetch_duplicate_class(connection_class_name)
        r = ActiveRecord::Relation.new(d, d.arel_table)
        r = r.readonly if d.connection.readonly?
        r
      end
        
      private       
      # We use dup here because its just too tricky to make sure we override
      # all the methods nesseccary when using a child class of the model. This 
      # action is lazy and the created sub is named to a constant so we only
      # have to do it once.
      def fetch_duplicate_class(connection_class_name)     
        begin
          return "#{self.name}::#{connection_class_name}Dup".constantize
        rescue NameError
          return build_dup_class(connection_class_name)
        end
      end
      
      def build_dup_class(connection_class_name)
        con_class = connection_class_name.constantize
        dup_klass = dup              
        dup_klass.class_eval <<-STR 
          self.table_name = '#{table_name_for_dup(con_class)}'
          class << self
            def model_name
              '#{self.name}'.constantize.model_name
            end
          end
        STR
        
        extend_dup_class(dup_klass,connection_class_name)          
        self.const_set("#{connection_class_name}Dup", dup_klass)
      end
      
      def table_name_for_dup(con_class)
        "#{con_class.table_name_prefix}#{table_name.split('.').last}"
      end
      
      def table_name_prefix_for_dup(con_class)
        con_class.abstract_class? ? table_name_prefix : con_class.table_name_prefix
      end
    
      # Extend the connection override module from the connetion to the supplied class
      def extend_dup_class(dup_class,connection_class_name)
        begin
          mod = "#{connection_class_name}::ConnectionOverrideMod".constantize
          dup_class.extend(mod)
        rescue NameError
          built = build_connection_override_module(connection_class_name).constantize
          dup_class.extend(built)
        end
      end
    
      # Added a module to the connection class. The module is extended on dup class
      # to override the connection and superclass
      def build_connection_override_module(connection_class_name)
        connection_class_name.constantize.class_eval <<-STR
        module ConnectionOverrideMod      
          def connection_class
            "#{connection_class_name}".constantize
          end
        
          def connection
            connection_class.connection
          end

          def superclass
            connection_class
          end
        end
        STR
        "#{connection_class_name}::ConnectionOverrideMod"
      end
    end
    
    # Instance method for casting to a duplication class
    def using(connection_class)
      becomes(self.class.using(connection_class).klass)
    end
    
    def self.included(host_class)
      host_class.extend(ClassMethods)
    end
  end
  
  module UsingQueryMethod
    def using(connection_class_name)
      d = klass.using(connection_class_name)
      relation = clone
      relation.instance_variable_set(:@klass, d.klass)
      relation
    end
  end
end
