require 'active_support/core_ext/module/delegation'
module ConnectionManager
  module Using
    module Relation

      # Specify connection class to used for query.For
      # example:
      #
      # users = User.using(MySlaveConnection).first
      def using(connection_class_name)
        @klass = ConnectionManager::Using::Proxy.new(@klass,connection_class_name)
        self
      end
    end

    class Proxy
      attr_accessor :klass, :connection_class
      
      def initialize(klass,connection_class)
        @klass = klass  # the @klass insance from an ActiveRecord::Relation
        @connection_class = (connection_class.is_a?(String) ? connection_class.constantize : connection_class)
      end

      # Use the connection from the connection class
      def connection
        ConnectionManager.logger.info "Using proxy connection: #{@connection_class.name} for #{@klass.name}" if ConnectionManager.logger
        @connection_class.connection
      end

      # Make sure we return the @klass superclass,
      # which used through the query building code in AR
      def superclass
        @klass.superclass
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
ActiveRecord::Relation.send(:include,ConnectionManager::Using::Relation)
module ActiveRecord
  class Base
    class << self
      delegate :using, :to => (ActiveRecord::VERSION::MAJOR == 4 ? :all : :scoped)
    end
  end
end
