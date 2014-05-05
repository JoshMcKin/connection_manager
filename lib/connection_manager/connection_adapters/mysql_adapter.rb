module ConnectionManager
  module MysqlAdapter

    # Force all tables to be cached for the life connection
    def cached_tables
      @cached_tables ||= {}
    end

    def new_tables(name = nil, database = nil, like =nil)
      return cached_tables[database] if cached_tables[database] && like.nil?
      cached_tables[database] ||= []
      return [like] if like && cached_tables[database].include?(like)
      sql = "SHOW TABLES "
      sql << "IN #{database} " if database
      sql << "LIKE #{quote(like)}" if like
      result = execute(sql, 'SCHEMA')
      cached_tables[database] = (cached_tables[database] | result.collect { |field| field[0] }).compact
    end
    alias :tables :new_tables


    # We have to clean the name of '`' and fetch table name with schema
    def table_exists?(name)
      return false unless name
      name          = name.to_s
      schema, table = name.split('.', 2)
      unless table # A table was provided without a schema
        table  = schema
        schema = nil
      end
      new_tables(nil, schema, table).include?(table)
    end
  end
end
if ActiveRecord::VERSION::MAJOR == 3 && ActiveRecord::VERSION::MINOR <= 1
  require 'active_record/connection_adapters/mysql2_adapter'
  ActiveRecord::ConnectionAdapters::MysqlAdapter.send(:include,(ConnectionManager::MysqlAdapter)) if defined?(ActiveRecord::ConnectionAdapters::MysqlAdapter)
  ActiveRecord::ConnectionAdapters::Mysql2Adapter.send(:include,(ConnectionManager::MysqlAdapter))
end
