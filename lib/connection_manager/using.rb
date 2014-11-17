module ConnectionManager
  module Using
    module ClassMethods
      def >=(compare)
        return self >= compare.klass if compare.is_a?(ConnectionManager::Using::Proxy)
        super(compare)
      end

      def ==(compare)
        return self == compare.klass if compare.is_a?(ConnectionManager::Using::Proxy)
        super(compare)
      end

      def !=(compare)
        return self != compare.klass if compare.is_a?(ConnectionManager::Using::Proxy)
        super(compare)
      end
    end
    class Proxy
      attr_accessor :klass, :connection_class

      def initialize(klass,connection_class)
        @klass = klass  # the @klass from an ActiveRecord::Relation
        @connection_class = (connection_class.is_a?(String) ? connection_class.constantize : connection_class)
        ConnectionManager.logger.info "Using proxy connection: #{@connection_class.name} for #{@klass.name}" if ConnectionManager.logger
      end

      # Use the connection from the connection class
      def connection
        @connection_class.connection
      end

      # Make sure we return the @klass superclass,
      # which used throughout the query building code in AR
      def superclass
        @klass.superclass
      end

      def >= compare
        return @klass >= compare.klass if compare.is_a?(self.class)
        @klass >= compare
      end

      def == compare
        return @klass == compare.klass if compare.is_a?(self.class)
        @klass == compare
      end

      def != compare
        return @klass != compare.klass if compare.is_a?(self.class)
        @klass != compare
      end

      def descendants
        @klass.descendants
      end

      def subclasses
        @klass.subclasses
      end

      def parent
        @klass.parent
      end

      if ActiveRecord::VERSION::MAJOR == 3 && ActiveRecord::VERSION::MINOR == 0
        # Rails 3.0
        def find_by_sql(sql)
          connection.select_all(sanitize_sql(sql), "#{name} Load").collect! { |record| instantiate(record) }
        end
        
      elsif ActiveRecord::VERSION::MAJOR == 3 && ActiveRecord::VERSION::MINOR == 1
        # Rails 3.1
        def find_by_sql(sql, binds = [])
          connection.select_all(sanitize_sql(sql), "#{name} Load", binds).collect! { |record| instantiate(record) }
        end

      elsif ActiveRecord::VERSION::MAJOR == 3
        # Rails 3.2
        def find_by_sql(sql, binds = [])
          logging_query_plan do
            connection.select_all(sanitize_sql(sql), "#{name} Load", binds).collect! { |record| instantiate(record) }
          end
        end

      elsif ActiveRecord::VERSION::MAJOR == 4 && ActiveRecord::VERSION::MINOR <= 1
        #Rails 4.0 & 4.1
        def find_by_sql(sql, binds = [])
          result_set = connection.select_all(sanitize_sql(sql), "#{name} Load", binds)
          column_types = {}
          if result_set.respond_to? :column_types
            column_types = result_set.column_types
          else
            ActiveSupport::Deprecation.warn "the object returned from `select_all` must respond to `column_types`"
          end
          result_set.map { |record| instantiate(record, column_types) }
        end

      else
        # Edge Rails
        def find_by_sql(sql, binds = [])
          result_set = connection.select_all(sanitize_sql(sql), "#{name} Load", binds)
          column_types = result_set.column_types.dup
          columns_hash.each_key { |k| column_types.delete k }
          message_bus = ActiveSupport::Notifications.instrumenter
          payload = {
            record_count: result_set.length,
            class_name: name
          }
          message_bus.instrument('instantiation.active_record', payload) do
            result_set.map { |record| instantiate(record, column_types) }
          end
        end
      end

      def count_by_sql(sql)
        sql = sanitize_conditions(sql)
        connection.select_value(sql, "#{name} Count").to_i
      end

      # Pass all methods to @klass, this ensures objects
      # build from the query are the correct class and
      # any settings in the model like table_name_prefix
      # are used.
      def method_missing(name, *args, &blk)
        @klass.send(name, *args,&blk)
      end

      def respond_to?(method_name, include_private = false)
        @klass.respond_to?(method_name) || super
      end
    end
  end
end
ActiveRecord::Relation.send(:extend, ConnectionManager::Using::ClassMethods)
ActiveRecord::Base.send(:extend, ConnectionManager::Using::ClassMethods)
