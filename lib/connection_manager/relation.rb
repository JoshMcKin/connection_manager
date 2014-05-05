module ConnectionManager
  module Relation
    # Specify connection class to used for query. For
    # example:
    #
    # users = User.using(MySlaveConnection).first
    def using(connection_class_name)
      @klass = ConnectionManager::Using::Proxy.new(@klass,connection_class_name)
      self
    end

    def slaves
      using(@klass.send(:fetch_slave_connection))
    end

    def masters
      using(@klass.send(:fetch_master_connection))
    end
  end
end
ActiveRecord::Relation.send(:include, ConnectionManager::Relation)
