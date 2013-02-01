# ActiveRecord 3.0 BACK PORT ONLY
# https://github.com/brianmario/mysql2/commit/14accdf8d1bf557f652c19b870316094a7441334#diff-0
if ActiveRecord::VERSION::MAJOR == 3 && ActiveRecord::VERSION::MINOR <= 2
  (require 'active_record/connection_adapters/abstract_mysql_adapter' if (ActiveRecord::VERSION::MAJOR == 3 && ActiveRecord::VERSION::MINOR == 2))
  module ActiveRecord
    module ConnectionAdapters
      class Mysql2Adapter < ((ActiveRecord::VERSION::MAJOR == 3 && ActiveRecord::VERSION::MINOR == 2) ? AbstractMysqlAdapter : AbstractAdapter)
        
        # Force all tables to be cached for the life connection
        def cached_tables
          @cached_tables ||= {}
        end
        
        def tables(name = nil, database = nil, like =nil)
          return cached_tables[database] if cached_tables[database] && like.nil?
          cached_tables[database] ||= []
          return [like] if like && cached_tables[database].include?(like)
          sql = "SHOW TABLES "
          sql << "IN #{quote_table_name(database)} " if database
          sql << "LIKE #{quote(like)}" if like
          result = execute(sql, 'SCHEMA')
          cached_tables[database] = (cached_tables[database] | result.collect { |field| field[0] }).compact
        end
        
        alias :new_tables :tables
        
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
  end 
end

# We need to make sure we override existing database_name name methods
module ActiveRecord
  class Base
    class << self
      # Returns the database_name of the connection unless set otherwise
      def database_name
        @database_name = "#{connection.config[:database].to_s}" if @database_name.blank?
        @database_name
      end
      alias :schema_name :database_name
    
      # Sometimes we need to manually set the database name, like when the connection
      # has a database but our table is in a different database/schema but on the
      # same DMS.
      def database_name=database_name
        @database_name = database_name
      end
      alias :schema_name= :database_name=
    end
  end
end
