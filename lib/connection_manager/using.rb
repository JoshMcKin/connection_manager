module ConnectionManager
  module Using
    class Proxy
      attr_accessor :klass, :connection_class
      
      def initialize(klass,connection_class)
        @klass = klass  # the @klass from an ActiveRecord::Relation
        @connection_class = (connection_class.is_a?(String) ? connection_class.constantize : connection_class)
      end

      # Use the connection from the connection class
      def connection
        ConnectionManager.logger.info "Using proxy connection: #{@connection_class.name} for #{@klass.name}" if ConnectionManager.logger
        @connection_class.connection
      end

      # Make sure we return the @klass superclass,
      # which used throughout the query building code in AR
      def superclass
        @klass.superclass
      end

      # https://github.com/rails/rails/blob/3-2-stable/activerecord/lib/active_record/relation/spawn_methods.rb#L154
      def >= compare
        @klass >= compare
      end

      def == compare
        @klass == compare
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