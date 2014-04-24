module ConnectionManager
  module Using
    module ClassMethods

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

      private
      # Modifies the dup class to use the connection class connection.
      # We want to use the current class table name, but the connection
      # class database as the prefix, useful when shards but normally
      # should be the same. We also want the superclass method to
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
end
module ActiveRecord
  # = Active Record Relation
  class Relation
    if ActiveRecord::VERSION::MAJOR == 4
      def using(connection_class_name)
        d = @klass.fetch_duplicate_class(connection_class_name)
        self.instance_variable_set(:@arel_table, d.arel_table)
        self.instance_variable_set(:@klass, d)
        self
      end
    else
      def using(connection_class_name)
        d = @klass.fetch_duplicate_class(connection_class_name)
        rel = clone
        rel.instance_variable_set(:@arel_table, d.arel_table)
        rel.instance_variable_set(:@klass, d)
        rel
      end
    end
  end
end

module ActiveRecord
  class Base
    class << self
      delegate :using, :to => (ActiveRecord::VERSION::MAJOR == 4 ? :all : :scoped)
    end
  end
end
