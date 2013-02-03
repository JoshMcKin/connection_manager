module ConnectionManager
  module Using
    module ClassMethods
      
      def using(connection_class_name)
        d = fetch_duplicate_class(connection_class_name)
        r = ActiveRecord::Relation.new(d, d.arel_table)
        r = r.readonly if d.connection.readonly?
        r.from(d.quoted_table_name)
      end
        
      private       
      # We use dup here because its just too tricky to make sure we override
      # all the methods necessary when using a child class of the model. This 
      # action is lazy and the created sub is named to a constant so we only
      # have to do it once.
      def fetch_duplicate_class(connection_class_name)     
        begin
          return "#{self.name}::#{connection_class_name}Dup".constantize
        rescue NameError
          return build_dup_class(connection_class_name)
        end
      end
      
      # Modifies the dup class to use the connection class connection.
      # We want to use the current class table name, but the connection
      # class database as the prefix. We also want the superclass method to 
      # return the connection class as AR sometimes uses the the superclass
      # connection
      def build_dup_class(connection_class_name)
        use_database(self.current_database_name) # make sure we are consistent from super to dup
        con_class = connection_class_name.constantize
        db_name = con_class.current_database_name
        dup_klass = dup              
        dup_klass.class_eval <<-STR
          self.use_database('#{db_name}',{:table_name => '#{table_name}'})
          class << self
            def model_name
              #{self.name}.model_name
            end
            def connection_class
              #{connection_class_name}
            end
            def connection
              connection_class.connection
            end
            def superclass
              connection_class
            end
          end
        STR
        
        self.const_set("#{connection_class_name}Dup", dup_klass)
        "#{self.name}::#{connection_class_name}Dup".constantize
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
      relation.from(d.quoted_table_name)
    end
  end
end
